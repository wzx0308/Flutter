import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class PromptTemplateService {
  private readonly logger = new Logger(PromptTemplateService.name);

  constructor(private prisma: PrismaService) {}

  async getAll() {
    return this.prisma.promptTemplate.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async getActive() {
    return this.prisma.promptTemplate.findFirst({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(name: string, systemPrompt: string, fewShotExamples?: any[]) {
    return this.prisma.promptTemplate.create({
      data: {
        name,
        systemPrompt,
        fewShotExamples: fewShotExamples || undefined,
      },
    });
  }

  async update(id: string, data: { name?: string; systemPrompt?: string; fewShotExamples?: any[]; isActive?: boolean }) {
    return this.prisma.promptTemplate.update({
      where: { id },
      data: {
        ...(data.name !== undefined && { name: data.name }),
        ...(data.systemPrompt !== undefined && { systemPrompt: data.systemPrompt }),
        ...(data.fewShotExamples !== undefined && { fewShotExamples: data.fewShotExamples }),
        ...(data.isActive !== undefined && { isActive: data.isActive }),
      },
    });
  }

  async delete(id: string) {
    return this.prisma.promptTemplate.delete({ where: { id } });
  }

  /**
   * 将模板 + few-shot + 用户消息组装成 OpenAI 格式
   */
  buildMessages(
    template: { systemPrompt: string; fewShotExamples?: any[] } | null,
    userMessages: Array<{ role: string; content: string | any[] }>,
  ): Array<{ role: string; content: string | any[] }> {
    const messages: Array<{ role: string; content: string | any[] }> = [];

    // 系统提示词
    const systemContent = template?.systemPrompt || '你是一个友好、有帮助的AI助手。请用中文回答用户的问题。';
    messages.push({ role: 'system', content: systemContent });

    // Few-shot 示例
    if (template?.fewShotExamples && Array.isArray(template.fewShotExamples)) {
      for (const example of template.fewShotExamples) {
        if (example.input) messages.push({ role: 'user', content: example.input });
        if (example.output) messages.push({ role: 'assistant', content: example.output });
      }
    }

    // 用户消息
    messages.push(...userMessages);

    return messages;
  }
}
