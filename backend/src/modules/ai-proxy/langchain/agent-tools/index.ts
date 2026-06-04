import { PrismaService } from '../../../../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import { createSearchPostsTool } from './search-posts.tool';
import { createGetUserInfoTool } from './get-user-info.tool';
import { createGetTrendingTool } from './get-trending.tool';
import { createWebSearchTool } from './web-search.tool';
import { createCalculatorTool } from './calculator.tool';
import { createSqlQueryTool } from './sql-query.tool';
import { createWeatherTool } from './weather.tool';
import { createImageOcrTool } from './image-ocr.tool';

export function createAgentTools(prisma: PrismaService, config?: ConfigService) {
  const tools = [
    // 平台数据工具
    createSearchPostsTool(prisma),
    createGetUserInfoTool(prisma),
    createGetTrendingTool(prisma),
    createSqlQueryTool(prisma),

    // 联网与外部工具
    createWebSearchTool(),
    createCalculatorTool(),
    createWeatherTool(),
  ];

  // 图片OCR工具（需要config）
  if (config) {
    tools.push(createImageOcrTool(config));
  }

  return tools;
}
