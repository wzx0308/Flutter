import { DynamicTool } from '@langchain/core/tools';
import { ChatOpenAI } from '@langchain/openai';
import { HumanMessage } from '@langchain/core/messages';
import { ConfigService } from '@nestjs/config';

/**
 * 图片OCR分析工具 - 使用AI视觉能力识别图片内容
 * 接收 base64 图片或图片URL，提取文字并分析内容
 */
export function createImageOcrTool(config: ConfigService) {
  const llm = new ChatOpenAI({
    modelName: 'mimo-v2.5',
    apiKey: config.get('AI_API_KEY'),
    configuration: {
      baseURL: config.get('AI_BASE_URL') || 'https://api.xiaomimimo.com/v1',
    },
    temperature: 0.1,
    maxTokens: 1024,
  });

  return new DynamicTool({
    name: 'image_ocr',
    description: '图片OCR识别工具，可识别图片中的文字内容并分析图片。输入图片的base64数据（data:image/...;base64,...格式）或图片URL，返回识别出的文字和内容分析。',
    func: async (input: string) => {
      try {
        const imageData = input.trim();

        // 构建多模态消息
        const content: any[] = [
          {
            type: 'text',
            text: '请识别这张图片中的所有文字内容，并对图片进行简要描述。如果图片中有表格、数据、二维码等，请提取其中的信息。请用中文回复。',
          },
        ];

        if (imageData.startsWith('data:image') || imageData.startsWith('http')) {
          content.push({
            type: 'image_url',
            image_url: { url: imageData },
          });
        } else {
          return JSON.stringify({ error: '请提供有效的图片数据（base64或URL）' });
        }

        const response = await llm.invoke([new HumanMessage({ content })]);
        const text = typeof response.content === 'string' ? response.content : JSON.stringify(response.content);

        return JSON.stringify({ result: text });
      } catch (e) {
        return JSON.stringify({ error: `图片识别失败: ${e.message}` });
      }
    },
  });
}
