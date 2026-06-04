import { Injectable, BadRequestException } from '@nestjs/common';

@Injectable()
export class SensitiveWordFilter {
  private readonly sensitiveWords: string[] = [
    // 基础敏感词库（生产环境应从数据库或配置文件加载）
    '赌博', '博彩', '色情', '暴力', '毒品',
    '枪支', '炸药', '诈骗', '传销', '邪教',
    'gambling', 'porn', 'violence', 'drugs',
  ];

  check(text: string): { passed: boolean; words: string[] } {
    if (!text) return { passed: true, words: [] };
    const found: string[] = [];
    for (const word of this.sensitiveWords) {
      if (text.includes(word)) {
        found.push(word);
      }
    }
    return { passed: found.length === 0, words: found };
  }

  validate(text: string): void {
    const result = this.check(text);
    if (!result.passed) {
      throw new BadRequestException(`内容包含敏感词: ${result.words.join(', ')}`);
    }
  }

  filter(text: string): string {
    let filtered = text;
    for (const word of this.sensitiveWords) {
      filtered = filtered.replaceAll(word, '*'.repeat(word.length));
    }
    return filtered;
  }
}
