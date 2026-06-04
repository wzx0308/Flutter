import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { ChatOpenAI } from '@langchain/openai';
import { HumanMessage, SystemMessage } from '@langchain/core/messages';
import { ConfigService } from '@nestjs/config';

interface Fact {
  category: string;
  key: string;
  value: string;
}

@Injectable()
export class LongTermMemoryService {
  private readonly logger = new Logger(LongTermMemoryService.name);
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
      temperature: 0.2,
      maxTokens: 512,
    });
  }

  /**
   * 加载用户的长期记忆
   */
  async loadMemory(userId: string): Promise<Fact[]> {
    const record = await this.prisma.longTermMemory.findUnique({
      where: { userId },
    });
    return (record?.facts as unknown as Fact[]) || [];
  }

  /**
   * 将长期记忆格式化为可注入的文本
   */
  formatFacts(facts: Fact[]): string {
    if (facts.length === 0) return '';
    const lines = facts.map((f) => `- ${f.category}：${f.key} = ${f.value}`);
    return lines.join('\n');
  }

  /**
   * 从对话中提取关键信息并合并到长期记忆
   * 异步调用，不阻塞主流程
   */
  async extractFacts(userId: string, userMessage: string, assistantReply: string): Promise<void> {
    try {
      // 加载已有记忆
      const existingFacts = await this.loadMemory(userId);
      const existingText = existingFacts.length > 0
        ? existingFacts.map((f) => `${f.category}|${f.key}|${f.value}`).join('\n')
        : '无';

      const prompt = `你是一个信息提取助手。从以下对话中提取关于用户的长期记忆信息（偏好、习惯、身份、兴趣等）。

【已有记忆】
${existingText}

【最新对话】
用户: ${userMessage}
AI: ${assistantReply}

【规则】
1. 只提取关于用户的事实信息，不提取对话内容本身
2. 如果已有记忆中的信息被更新，修改而非新增
3. 如果没有值得记忆的新信息，返回空数组
4. 每条记忆格式：类别|键|值（如：个人偏好|喜欢的食物|火锅）

请以JSON数组格式返回，每条记忆为 {"category":"类别","key":"键","value":"值"}。
只返回JSON数组，不要其他文字。`;

      const response = await this.llm.invoke([
        new SystemMessage('你是一个精确的信息提取助手，只输出JSON。'),
        new HumanMessage(prompt),
      ]);

      const text = typeof response.content === 'string' ? response.content : JSON.stringify(response.content);

      // 解析 JSON
      const jsonMatch = text.match(/\[[\s\S]*\]/);
      if (!jsonMatch) return;

      const newFacts: Fact[] = JSON.parse(jsonMatch[0]);
      if (!Array.isArray(newFacts) || newFacts.length === 0) return;

      // 合并：去重（同 category+key 则更新 value）
      const merged = [...existingFacts];
      for (const fact of newFacts) {
        if (!fact.category || !fact.key || !fact.value) continue;
        const idx = merged.findIndex((f) => f.category === fact.category && f.key === fact.key);
        if (idx >= 0) {
          merged[idx].value = fact.value;
        } else {
          merged.push(fact);
        }
      }

      // 保存
      await this.saveMemory(userId, merged);
      this.logger.log(`长期记忆更新: userId=${userId}, 新增${newFacts.length}条, 总计${merged.length}条`);
    } catch (e) {
      this.logger.error(`长期记忆提取失败: ${e.message}`);
    }
  }

  /**
   * 保存长期记忆
   */
  async saveMemory(userId: string, facts: Fact[]): Promise<void> {
    await this.prisma.longTermMemory.upsert({
      where: { userId },
      update: { facts: facts as any },
      create: { userId, facts: facts as any },
    });
  }
}
