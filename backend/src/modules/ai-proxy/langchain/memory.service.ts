import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { ChatOpenAI } from '@langchain/openai';
import { HumanMessage, AIMessage, SystemMessage } from '@langchain/core/messages';
import { ConfigService } from '@nestjs/config';

const MAX_ROUNDS = 8; // 保留最近8轮对话
const MAX_RECENT_MESSAGES = MAX_ROUNDS * 2; // 16条消息（8轮 user+assistant）
const SUMMARIZE_THRESHOLD = 20; // 超过20条时触发摘要
const SUMMARIZE_BATCH = 8; // 每次摘要8条

@Injectable()
export class MemoryService {
  private readonly logger = new Logger(MemoryService.name);
  private llm: ChatOpenAI;

  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
  ) {
    this.llm = new ChatOpenAI({
      modelName: 'mimo-v2.5',
      apiKey: this.config.get('AI_API_KEY'),
      configuration: {
        baseURL: this.config.get('AI_BASE_URL') || 'https://api.xiaomimimo.com/v1',
      },
      temperature: 0.3,
      maxTokens: 512,
    });
  }

  async loadMemory(userId: string, conversationId: string) {
    const record = await this.prisma.conversationMemory.findFirst({
      where: { userId, conversationId },
    });

    if (!record) {
      return { summary: null, messages: [] };
    }

    return {
      summary: record.summary,
      messages: (record.messages as any[]) || [],
    };
  }

  async saveMessage(userId: string, conversationId: string, role: string, content: string) {
    const record = await this.prisma.conversationMemory.findFirst({
      where: { userId, conversationId },
    });

    const newMessage = { role, content, timestamp: new Date().toISOString() };

    if (!record) {
      await this.prisma.conversationMemory.create({
        data: {
          userId,
          conversationId,
          messages: [newMessage],
        },
      });
      return;
    }

    const messages = (record.messages as any[]) || [];
    messages.push(newMessage);

    // 超过阈值时触发摘要
    if (messages.length > SUMMARIZE_THRESHOLD) {
      const toSummarize = messages.splice(0, SUMMARIZE_BATCH);
      const summary = await this.summarize(record.summary, toSummarize);

      await this.prisma.conversationMemory.update({
        where: { id: record.id },
        data: {
          messages: messages.slice(-MAX_RECENT_MESSAGES),
          summary,
        },
      });
    } else {
      await this.prisma.conversationMemory.update({
        where: { id: record.id },
        data: { messages },
      });
    }
  }

  private async summarize(existingSummary: string | null, messages: any[]): Promise<string> {
    const conversationText = messages
      .map((m) => `${m.role === 'user' ? '用户' : 'AI'}: ${m.content}`)
      .join('\n');

    const prompt = existingSummary
      ? `请将以下对话摘要与已有摘要合并，生成一段简洁的中文摘要（不超过200字）。\n\n已有摘要：${existingSummary}\n\n新对话：\n${conversationText}\n\n合并后的摘要：`
      : `请将以下对话总结为一段简洁的中文摘要（不超过200字）。\n\n${conversationText}\n\n摘要：`;

    try {
      const response = await this.llm.invoke([new HumanMessage(prompt)]);
      const text = typeof response.content === 'string' ? response.content : JSON.stringify(response.content);
      return text.trim();
    } catch (e) {
      this.logger.error(`摘要生成失败: ${e.message}`);
      return existingSummary || '';
    }
  }

  /**
   * 组装带记忆上下文的消息列表
   */
  buildContext(
    memory: { summary: string | null; messages: any[] },
    currentMessages: Array<{ role: string; content: string | any[] }>,
    longTermMemoryText?: string,
  ): Array<{ role: string; content: string | any[] }> {
    const result: Array<{ role: string; content: string | any[] }> = [];

    // 长期记忆注入（最高优先级）
    if (longTermMemoryText) {
      result.push({
        role: 'system',
        content: `以下是关于该用户的长期记忆信息，请在回答时参考这些信息：\n${longTermMemoryText}`,
      });
    }

    // 如果有摘要，作为系统消息注入
    if (memory.summary) {
      result.push({
        role: 'system',
        content: `以下是之前对话的摘要，请基于此上下文回答：\n${memory.summary}`,
      });
    }

    // 加入历史消息（最多最近 10 条）
    const recentHistory = memory.messages.slice(-10);
    for (const msg of recentHistory) {
      result.push({ role: msg.role, content: msg.content });
    }

    // 加入当前消息
    result.push(...currentMessages);

    return result;
  }
}
