import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ChatOpenAI } from '@langchain/openai';
import { HumanMessage, SystemMessage, AIMessage, ToolMessage } from '@langchain/core/messages';
import { PrismaService } from '../../../prisma/prisma.service';
import { PromptTemplateService } from './prompt-template.service';
import { MemoryService } from './memory.service';
import { RagService } from './rag.service';
import { LongTermMemoryService } from './long-term-memory.service';
import { createAgentTools } from './agent-tools';

@Injectable()
export class LangchainService {
  private readonly logger = new Logger(LangchainService.name);
  private llm: ChatOpenAI;

  constructor(
    private config: ConfigService,
    private prisma: PrismaService,
    private promptTemplateService: PromptTemplateService,
    private memoryService: MemoryService,
    private ragService: RagService,
    private longTermMemoryService: LongTermMemoryService,
  ) {
    this.llm = new ChatOpenAI({
      modelName: 'mimo-v2.5',
      apiKey: this.config.get('AI_API_KEY'),
      configuration: {
        baseURL: this.config.get('AI_BASE_URL') || 'https://api.xiaomimimo.com/v1',
      },
      temperature: 0.7,
      maxTokens: 2048,
    });
  }

  /**
   * 标准模式：直接调用 LLM（带 Prompt 模板 + 记忆）
   */
  async standardChat(
    messages: Array<{ role: string; content: string | any[] }>,
    options?: { userId?: string; conversationId?: string },
  ): Promise<string> {
    // 获取 Prompt 模板
    const template = await this.promptTemplateService.getActive();

    // 组装带模板的消息
    const templateData = template ? {
      systemPrompt: template.systemPrompt,
      fewShotExamples: template.fewShotExamples as any[] || undefined,
    } : null;
    let formattedMessages = this.promptTemplateService.buildMessages(templateData, messages);

    // 如果有用户ID和会话ID，加载记忆
    if (options?.userId && options?.conversationId) {
      const memory = await this.memoryService.loadMemory(options.userId, options.conversationId);
      const ltFacts = options.userId ? await this.longTermMemoryService.loadMemory(options.userId) : [];
      const ltText = this.longTermMemoryService.formatFacts(ltFacts);
      formattedMessages = this.memoryService.buildContext(memory, formattedMessages, ltText);
    }

    // 调用 LLM
    const langchainMessages = formattedMessages.map((m) => {
      if (m.role === 'system') return new SystemMessage(m.content as string);
      if (m.role === 'assistant') return new AIMessage(m.content as string);
      return new HumanMessage(m.content as string);
    });

    const response = await this.llm.invoke(langchainMessages);
    const reply = typeof response.content === 'string' ? response.content : JSON.stringify(response.content);

    // 保存对话记忆 + 异步提取长期记忆
    if (options?.userId && options?.conversationId) {
      const lastUser = messages.filter((m) => m.role === 'user').pop();
      if (lastUser) {
        await this.memoryService.saveMessage(options.userId, options.conversationId, 'user', lastUser.content as string);
        // 异步提取长期记忆，不阻塞响应
        this.longTermMemoryService.extractFacts(options.userId, lastUser.content as string, reply).catch(() => {});
      }
      await this.memoryService.saveMessage(options.userId, options.conversationId, 'assistant', reply);
    }

    return reply;
  }

  /**
   * 标准模式流式对话（SSE 逐字输出）
   */
  async *standardChatStream(
    messages: Array<{ role: string; content: string | any[] }>,
    options?: { userId?: string; conversationId?: string },
  ): AsyncGenerator<string> {
    const template = await this.promptTemplateService.getActive();
    const templateData = template ? {
      systemPrompt: template.systemPrompt,
      fewShotExamples: template.fewShotExamples as any[] || undefined,
    } : null;
    let formattedMessages = this.promptTemplateService.buildMessages(templateData, messages);

    if (options?.userId && options?.conversationId) {
      const memory = await this.memoryService.loadMemory(options.userId, options.conversationId);
      const ltFacts = options.userId ? await this.longTermMemoryService.loadMemory(options.userId) : [];
      const ltText = this.longTermMemoryService.formatFacts(ltFacts);
      formattedMessages = this.memoryService.buildContext(memory, formattedMessages, ltText);
    }

    const langchainMessages = formattedMessages.map((m) => {
      if (m.role === 'system') return new SystemMessage(m.content as string);
      if (m.role === 'assistant') return new AIMessage(m.content as string);
      return new HumanMessage(m.content as string);
    });

    let fullReply = '';
    const stream = await this.llm.stream(langchainMessages);
    for await (const chunk of stream) {
      const text = typeof chunk.content === 'string' ? chunk.content : '';
      if (text) {
        fullReply += text;
        yield text;
      }
    }

    if (options?.userId && options?.conversationId && fullReply) {
      const lastUser = messages.filter((m) => m.role === 'user').pop();
      if (lastUser) {
        await this.memoryService.saveMessage(options.userId, options.conversationId, 'user', lastUser.content as string);
        this.longTermMemoryService.extractFacts(options.userId, lastUser.content as string, fullReply).catch(() => {});
      }
      await this.memoryService.saveMessage(options.userId, options.conversationId, 'assistant', fullReply);
    }
  }

  /**
   * RAG 模式：检索增强生成
   */
  async ragChat(
    messages: Array<{ role: string; content: string | any[] }>,
    options?: { userId?: string; conversationId?: string },
  ): Promise<string> {
    // 提取用户最后一条消息作为查询
    const lastUserMessage = messages.filter((m) => m.role === 'user').pop();
    const query = lastUserMessage ? (typeof lastUserMessage.content === 'string' ? lastUserMessage.content : JSON.stringify(lastUserMessage.content)) : '';

    // 获取用户已索引的文档 ID，限定检索范围
    let sourceIds: string[] | undefined;
    if (options?.userId) {
      const userDocs = await this.prisma.ragDocument.findMany({
        where: { userId: options.userId, status: 'indexed' },
        select: { id: true },
      });
      sourceIds = userDocs.map((d) => d.id);
    }

    // 检索相关文档
    const relevantDocs = await this.ragService.searchRelevant(query, 5, sourceIds);

    // 构建 RAG 上下文
    let context = '';
    if (relevantDocs.length > 0) {
      context = '以下是与问题相关的社区内容，请基于这些信息回答：\n\n';
      for (const doc of relevantDocs) {
        context += `---\n${doc.content}\n`;
      }
      context += '\n---\n\n';
    }

    // 获取模板
    const template = await this.promptTemplateService.getActive();
    const systemPrompt = template?.systemPrompt || '你是「安隅」社交APP专属智能小助手，温柔亲切地回答用户的问题。';

    // 组装消息
    const ragSystemPrompt = context
      ? `${systemPrompt}\n\n${context}`
      : systemPrompt;

    const formattedMessages = [
      { role: 'system', content: ragSystemPrompt },
      ...messages.filter((m) => m.role !== 'system'),
    ];

    // 加载记忆
    let finalMessages = formattedMessages;
    if (options?.userId && options?.conversationId) {
      const memory = await this.memoryService.loadMemory(options.userId, options.conversationId);
      const ltFacts = options.userId ? await this.longTermMemoryService.loadMemory(options.userId) : [];
      const ltText = this.longTermMemoryService.formatFacts(ltFacts);
      finalMessages = this.memoryService.buildContext(memory, formattedMessages, ltText);
    }

    // 调用 LLM
    const langchainMessages = finalMessages.map((m) => {
      if (m.role === 'system') return new SystemMessage(m.content as string);
      if (m.role === 'assistant') return new AIMessage(m.content as string);
      return new HumanMessage(m.content as string);
    });

    const response = await this.llm.invoke(langchainMessages);
    const reply = typeof response.content === 'string' ? response.content : JSON.stringify(response.content);

    // 保存记忆 + 异步提取长期记忆
    if (options?.userId && options?.conversationId) {
      if (lastUserMessage) {
        await this.memoryService.saveMessage(options.userId, options.conversationId, 'user', lastUserMessage.content as string);
        this.longTermMemoryService.extractFacts(options.userId, lastUserMessage.content as string, reply).catch(() => {});
      }
      await this.memoryService.saveMessage(options.userId, options.conversationId, 'assistant', reply);
    }

    return reply;
  }

  /**
   * Agent 模式：带工具调用（手动实现 tool-calling 循环）
   */
  async agentChat(
    messages: Array<{ role: string; content: string | any[] }>,
    options?: { userId?: string; conversationId?: string },
  ): Promise<string> {
    // 获取模板
    const template = await this.promptTemplateService.getActive();
    const systemPrompt = template?.systemPrompt || '你是「安隅」社交APP专属智能小助手。你可以使用工具来查询社区数据。请用中文温柔亲切地回答用户的问题。';

    // 获取工具
    const tools = createAgentTools(this.prisma, this.config);

    // 构建工具描述
    const toolDescriptions = tools.map((t) => `- ${t.name}: ${t.description}`).join('\n');

    // 加载聊天历史 + 长期记忆
    const historyMessages: Array<SystemMessage | HumanMessage | AIMessage> = [];
    if (options?.userId && options?.conversationId) {
      const memory = await this.memoryService.loadMemory(options.userId, options.conversationId);
      for (const msg of memory.messages.slice(-10)) {
        if (msg.role === 'user') historyMessages.push(new HumanMessage(msg.content));
        else if (msg.role === 'assistant') historyMessages.push(new AIMessage(msg.content));
      }
      // 注入长期记忆到系统提示
      const ltFacts = options.userId ? await this.longTermMemoryService.loadMemory(options.userId) : [];
      const ltText = this.longTermMemoryService.formatFacts(ltFacts);
      if (ltText) {
        historyMessages.unshift(new SystemMessage(`以下是关于该用户的长期记忆信息：\n${ltText}`));
      }
    }

    // 提取用户输入
    const lastUserMessage = messages.filter((m) => m.role === 'user').pop();
    const input = lastUserMessage ? (typeof lastUserMessage.content === 'string' ? lastUserMessage.content : JSON.stringify(lastUserMessage.content)) : '';

    // 带工具说明的系统提示
    const agentSystemPrompt = `${systemPrompt}

【可用工具】
你可以使用以下工具获取实时信息和执行任务，当你需要查询数据或执行计算时，请使用JSON格式调用工具：
${toolDescriptions}

【工具调用格式】
每次需要使用工具时，回复格式为：
{"tool": "工具名称", "input": "输入参数"}

【自主决策规则】
1. 你有多个工具可用，根据用户问题自主判断使用哪个工具
2. 可以连续调用多个工具完成复杂任务（最多5轮）
3. 不要编造数据，必须使用工具获取真实信息
4. 先思考需要什么信息，再选择合适的工具
5. 如果一个问题需要多步操作，逐步调用工具并整合结果
6. 将工具返回的结果用自然语言组织后回复用户，不要直接暴露JSON原始数据`;

    // Tool-calling 循环（最多 5 轮，支持复杂多步任务）
    const allMessages: Array<SystemMessage | HumanMessage | AIMessage> = [
      new SystemMessage(agentSystemPrompt),
      ...historyMessages,
      new HumanMessage(input),
    ];

    for (let round = 0; round < 5; round++) {
      const response = await this.llm.invoke(allMessages);
      const content = typeof response.content === 'string' ? response.content : JSON.stringify(response.content);

      // 检查是否包含工具调用
      const toolMatch = content.match(/\{"tool":\s*"(\w+)",\s*"input":\s*"([^"]*)"\}/);
      if (!toolMatch) {
        // 没有工具调用，直接返回回复
        if (options?.userId && options?.conversationId) {
          if (lastUserMessage) {
            await this.memoryService.saveMessage(options.userId, options.conversationId, 'user', lastUserMessage.content as string);
            this.longTermMemoryService.extractFacts(options.userId, lastUserMessage.content as string, content).catch(() => {});
          }
          await this.memoryService.saveMessage(options.userId, options.conversationId, 'assistant', content);
        }
        return content;
      }

      // 执行工具
      const toolName = toolMatch[1];
      const toolInput = toolMatch[2];
      const tool = tools.find((t) => t.name === toolName);

      let toolResult: string;
      if (tool) {
        try {
          toolResult = await tool.invoke(toolInput);
        } catch (e) {
          toolResult = JSON.stringify({ error: e.message });
        }
      } else {
        toolResult = JSON.stringify({ error: `工具 ${toolName} 不存在` });
      }

      // 将工具结果添加到消息中继续对话
      allMessages.push(response);
      allMessages.push(new AIMessage(`工具 ${toolName} 返回结果：${toolResult}`));
    }

    // 超过最大轮次
    const finalReply = '抱歉，处理过程中出现了问题，请重试。';
    if (options?.userId && options?.conversationId) {
      if (lastUserMessage) {
        await this.memoryService.saveMessage(options.userId, options.conversationId, 'user', lastUserMessage.content as string);
        this.longTermMemoryService.extractFacts(options.userId, lastUserMessage.content as string, finalReply).catch(() => {});
      }
      await this.memoryService.saveMessage(options.userId, options.conversationId, 'assistant', finalReply);
    }
    return finalReply;
  }
}
