import { DynamicTool } from '@langchain/core/tools';
import { PrismaService } from '../../../../prisma/prisma.service';

export function createSearchPostsTool(prisma: PrismaService) {
  return new DynamicTool({
    name: 'search_posts',
    description: '搜索社区帖子。输入搜索关键词，返回匹配的帖子列表。适用于用户询问关于社区内容的问题。',
    func: async (input: string) => {
      try {
        const params = JSON.parse(input);
        const query = params.query || input;
        const limit = params.limit || 5;

        const posts = await prisma.post.findMany({
          where: {
            OR: [
              { content: { contains: query, mode: 'insensitive' } },
              { title: { contains: query, mode: 'insensitive' } },
            ],
            status: 'PUBLISHED',
          },
          take: limit,
          orderBy: { createdAt: 'desc' },
          include: {
            author: { select: { id: true, nickname: true, username: true } },
          },
        });

        if (posts.length === 0) {
          return JSON.stringify({ results: [], message: '未找到相关帖子' });
        }

        return JSON.stringify({
          results: posts.map((p) => ({
            id: p.id,
            title: p.title,
            content: p.content?.substring(0, 200),
            author: p.author?.nickname || p.author?.username,
            likeCount: p.likeCount,
            commentCount: p.commentCount,
            createdAt: p.createdAt,
          })),
        });
      } catch (e) {
        return JSON.stringify({ error: e.message });
      }
    },
  });
}
