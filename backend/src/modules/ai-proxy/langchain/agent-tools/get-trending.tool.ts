import { DynamicTool } from '@langchain/core/tools';
import { PrismaService } from '../../../../prisma/prisma.service';

export function createGetTrendingTool(prisma: PrismaService) {
  return new DynamicTool({
    name: 'get_trending_posts',
    description: '获取当前热门帖子。可选传入数量参数（默认5条）。返回按热度排序的帖子列表。',
    func: async (input: string) => {
      try {
        const params = input.trim() ? JSON.parse(input) : {};
        const limit = params.limit || 5;

        const posts = await prisma.post.findMany({
          where: { status: 'PUBLISHED' },
          take: limit,
          orderBy: [
            { likeCount: 'desc' },
            { commentCount: 'desc' },
            { createdAt: 'desc' },
          ],
          include: {
            author: { select: { id: true, nickname: true, username: true } },
          },
        });

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
