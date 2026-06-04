import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import * as fs from 'fs';

@Injectable()
export class TextExtractionService {
  private readonly logger = new Logger(TextExtractionService.name);

  async extractText(filePath: string, mimeType: string): Promise<string> {
    let text: string;

    switch (mimeType) {
      case 'application/pdf':
        text = await this.extractPdf(filePath);
        break;
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        text = await this.extractDocx(filePath);
        break;
      case 'text/plain':
      case 'text/markdown':
        text = fs.readFileSync(filePath, 'utf-8');
        break;
      default:
        throw new BadRequestException(`不支持的文件类型: ${mimeType}`);
    }

    return this.cleanText(text);
  }

  private async extractPdf(filePath: string): Promise<string> {
    const pdfParse = await import('pdf-parse');
    const buffer = fs.readFileSync(filePath);
    const data = await (pdfParse as any).default(buffer);
    return data.text || '';
  }

  private async extractDocx(filePath: string): Promise<string> {
    const mammoth = await import('mammoth');
    const buffer = fs.readFileSync(filePath);
    const result = await mammoth.extractRawText({ buffer });
    return result.value || '';
  }

  private cleanText(text: string): string {
    return text
      .replace(/\r\n/g, '\n')
      .replace(/\t/g, ' ')
      .replace(/ {3,}/g, '  ')
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  }
}
