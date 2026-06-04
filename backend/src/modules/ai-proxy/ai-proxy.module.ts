import { Module } from '@nestjs/common';
import { AiProxyController } from './ai-proxy.controller';
import { LangchainService } from './langchain/langchain.service';
import { PromptTemplateService } from './langchain/prompt-template.service';
import { MemoryService } from './langchain/memory.service';
import { RagService } from './langchain/rag.service';
import { TextExtractionService } from './langchain/text-extraction.service';
import { LongTermMemoryService } from './langchain/long-term-memory.service';
import { PrismaService } from '../../prisma/prisma.service';

@Module({
  controllers: [AiProxyController],
  providers: [
    LangchainService,
    PromptTemplateService,
    MemoryService,
    RagService,
    TextExtractionService,
    LongTermMemoryService,
    PrismaService,
  ],
  exports: [LangchainService, PromptTemplateService, RagService],
})
export class AiProxyModule {}
