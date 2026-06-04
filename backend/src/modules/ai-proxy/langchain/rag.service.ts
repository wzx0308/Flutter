import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { OpenAIEmbeddings } from '@langchain/openai';
import { ConfigService } from '@nestjs/config';
import { RecursiveCharacterTextSplitter } from '@langchain/textsplitters';

const CHUNK_SIZE = 500;
const CHUNK_OVERLAP = 50;
const DEFAULT_TOP_K = 5;

@Injectable()
export class RagService {
  private readonly logger = new Logger(RagService.name);
  private embeddings: OpenAIEmbeddings;

  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
  ) {
    this.embeddings = new OpenAIEmbeddings({
      modelName: 'text-embedding-v3',
      apiKey: this.config.get('AI_API_KEY'),
      configuration: {
        baseURL: this.config.get('AI_BASE_URL') || 'https://api.xiaomimimo.com/v1',
      },
    });
  }

  /**
   * 索引单个文档（分块 + 向量化 + 存储）
   */
  async indexDocument(
    sourceType: string,
    sourceId: string,
    content: string,
    metadata?: Record<string, any>,
  ) {
    if (!content || content.trim().length === 0) return 0;

    // 先删除该文档的旧块
    await this.deleteBySource(sourceType, sourceId);

    // 分块
    const splitter = new RecursiveCharacterTextSplitter({
      chunkSize: CHUNK_SIZE,
      chunkOverlap: CHUNK_OVERLAP,
      separators: ['\n\n', '\n', '。', '！', '？', '.', '!', '?', ' ', ''],
    });

    const chunks = await splitter.splitText(content);
    if (chunks.length === 0) return 0;

    // 向量化
    let embeddings: number[][];
    try {
      embeddings = await this.embeddings.embedDocuments(chunks);
    } catch (e) {
      this.logger.error(`向量化失败: ${e.message}`);
      // 降级：不存储向量，仅存储文本块
      for (const chunk of chunks) {
        await this.prisma.documentChunk.create({
          data: {
            sourceType,
            sourceId,
            content: chunk,
            metadata: metadata || undefined,
            embedding: undefined,
          },
        });
      }
      return chunks.length;
    }

    // 存储到数据库
    for (let i = 0; i < chunks.length; i++) {
      await this.prisma.documentChunk.create({
        data: {
          sourceType,
          sourceId,
          content: chunks[i],
          metadata: metadata || undefined,
          embedding: embeddings[i] || undefined,
        },
      });
    }

    this.logger.log(`索引完成: ${sourceType}/${sourceId}, ${chunks.length} 个块`);
    return chunks.length;
  }

  /**
   * 批量索引帖子
   */
  async indexPosts(postIds?: string[]) {
    const where = postIds ? { id: { in: postIds } } : {};
    const posts = await this.prisma.post.findMany({
      where,
      select: { id: true, content: true, title: true, tags: true },
    });

    let total = 0;
    for (const post of posts) {
      const text = [post.title, post.content].filter(Boolean).join('\n\n');
      const count = await this.indexDocument('post', post.id, text, {
        title: post.title,
        tags: post.tags,
      });
      total += count;
    }

    this.logger.log(`批量索引完成: ${posts.length} 篇帖子, ${total} 个块`);
    return { posts: posts.length, chunks: total };
  }

  /**
   * 相似度搜索
   */
  async searchRelevant(query: string, topK = DEFAULT_TOP_K, sourceIds?: string[]) {
    // 向量化查询
    let queryEmbedding: number[];
    try {
      const result = await this.embeddings.embedQuery(query);
      queryEmbedding = result;
    } catch (e) {
      this.logger.error(`查询向量化失败: ${e.message}`);
      // 降级：使用全文搜索
      return this.fallbackSearch(query, topK, sourceIds);
    }

    // 构建查询条件
    const where: any = { embedding: { not: undefined } };
    if (sourceIds && sourceIds.length > 0) {
      where.OR = [
        { sourceType: 'rag_document', sourceId: { in: sourceIds } },
        { sourceType: { not: 'rag_document' } }, // 保留内置知识库
      ];
    }

    // 从数据库加载有向量的块
    const chunks = await this.prisma.documentChunk.findMany({
      where,
      take: 1000,
    });

    if (chunks.length === 0) {
      return this.fallbackSearch(query, topK);
    }

    // 计算余弦相似度并排序
    const scored = chunks
      .map((chunk) => {
        const emb = chunk.embedding as unknown as number[];
        if (!emb || emb.length === 0) return null;
        const similarity = this.cosineSimilarity(queryEmbedding, emb);
        return { ...chunk, similarity };
      })
      .filter((item): item is NonNullable<typeof item> => item !== null)
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, topK);

    return scored.map((item) => ({
      content: item.content,
      sourceType: item.sourceType,
      sourceId: item.sourceId,
      metadata: item.metadata,
      similarity: item.similarity,
    }));
  }

  /**
   * 降级全文搜索（当向量化不可用时）
   */
  private async fallbackSearch(query: string, limit: number, sourceIds?: string[]) {
    let chunks: any[];
    if (sourceIds && sourceIds.length > 0) {
      chunks = await this.prisma.$queryRaw<any[]>`
        SELECT id, source_type, source_id, content, metadata
        FROM document_chunks
        WHERE content ILIKE ${'%' + query + '%'}
          AND (source_type != 'rag_document' OR source_id = ANY(${sourceIds}))
        LIMIT ${limit}
      `;
    } else {
      chunks = await this.prisma.$queryRaw<any[]>`
        SELECT id, source_type, source_id, content, metadata
        FROM document_chunks
        WHERE content ILIKE ${'%' + query + '%'}
        LIMIT ${limit}
      `;
    }

    return chunks.map((c) => ({
      content: c.content,
      sourceType: c.source_type,
      sourceId: c.source_id,
      metadata: c.metadata,
      similarity: 0.5,
    }));
  }

  /**
   * 余弦相似度计算
   */
  private cosineSimilarity(a: number[], b: number[]): number {
    if (a.length !== b.length) return 0;
    let dotProduct = 0;
    let normA = 0;
    let normB = 0;
    for (let i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA === 0 || normB === 0) return 0;
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
  }

  /**
   * 删除某文档的所有块
   */
  async deleteBySource(sourceType: string, sourceId: string) {
    await this.prisma.documentChunk.deleteMany({
      where: { sourceType, sourceId },
    });
  }

  /**
   * 获取索引统计
   */
  async getStats() {
    const total = await this.prisma.documentChunk.count();
    const byType = await this.prisma.documentChunk.groupBy({
      by: ['sourceType'],
      _count: true,
    });
    return { total, byType };
  }
}
