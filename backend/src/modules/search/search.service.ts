import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SearchService {
  constructor(private prisma: PrismaService) {}

  async search(query: string, type?: string, page = 1, pageSize = 20) {
    if (!query || query.trim().length === 0) return { users: [], posts: [] };

    const q = query.trim();

    if (type === 'user') {
      return { users: await this.searchUsers(q, page, pageSize), posts: [] };
    }
    if (type === 'post') {
      return { users: [], posts: await this.searchPosts(q, page, pageSize) };
    }

    const [users, posts] = await Promise.all([
      this.searchUsers(q, 1, 10),
      this.searchPosts(q, 1, 20),
    ]);
    return { users, posts };
  }

  private async searchUsers(query: string, page: number, pageSize: number) {
    return this.prisma.user.findMany({
      where: {
        status: 'NORMAL',
        OR: [
          { username: { contains: query, mode: 'insensitive' } },
          { nickname: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true, username: true, nickname: true, avatar: true, bio: true,
        followerCount: true, followingCount: true, postCount: true,
      },
      skip: (page - 1) * pageSize,
      take: pageSize,
      orderBy: { followerCount: 'desc' },
    });
  }

  private async searchPosts(query: string, page: number, pageSize: number) {
    return this.prisma.post.findMany({
      where: {
        status: 'PUBLISHED',
        OR: [
          { content: { contains: query, mode: 'insensitive' } },
          { title: { contains: query, mode: 'insensitive' } },
        ],
      },
      include: {
        author: { select: { id: true, username: true, nickname: true, avatar: true } },
      },
      skip: (page - 1) * pageSize,
      take: pageSize,
      orderBy: { createdAt: 'desc' },
    });
  }

  async getTrending() {
    // 扫描最近 200 篇已发布帖子的标签，按热度加权统计
    const posts = await this.prisma.post.findMany({
      where: { status: 'PUBLISHED' },
      orderBy: { createdAt: 'desc' },
      take: 200,
      select: { tags: true, likeCount: true, commentCount: true, createdAt: true },
    });

    const tagScore: Record<string, number> = {};
    const now = new Date();

    for (const post of posts) {
      if (!post.tags) continue;
      const tags = post.tags as string[];
      // 热度分 = 点赞数 + 评论数 * 2 + 时间衰减加分
      const hoursAgo = (now.getTime() - new Date(post.createdAt).getTime()) / (1000 * 60 * 60);
      const timeBoost = Math.max(0, 10 - hoursAgo / 24); // 10天内有时间加分
      const score = (post.likeCount || 0) + (post.commentCount || 0) * 2 + timeBoost;

      for (const tag of tags) {
        tagScore[tag] = (tagScore[tag] || 0) + score;
      }
    }

    return Object.entries(tagScore)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 20)
      .map(([tag, score]) => ({ tag, count: Math.round(score) }));
  }

  async getRecommended(userId?: string, page = 1, pageSize = 20) {
    const skip = (page - 1) * pageSize;

    // Fetch all published post IDs, then randomly pick a page worth
    const allPosts = await this.prisma.post.findMany({
      where: { status: 'PUBLISHED' },
      select: { id: true },
    });

    // Shuffle and pick the requested page
    const shuffled = allPosts.sort(() => Math.random() - 0.5);
    const pageIds = shuffled.slice(skip, skip + pageSize).map((p) => p.id);

    if (pageIds.length === 0) return [];

    return this.prisma.post.findMany({
      where: { id: { in: pageIds } },
      include: {
        author: { select: { id: true, username: true, nickname: true, avatar: true } },
      },
    });
  }

  async getNearby(latitude: number, longitude: number, radiusKm = 10, page = 1, pageSize = 20) {
    const posts = await this.prisma.$queryRaw`
      SELECT p.*, json_build_object(
        'id', u.id, 'username', u.username, 'nickname', u.nickname, 'avatar', u.avatar
      ) as author
      FROM posts p
      JOIN users u ON p.author_id = u.id
      WHERE p.status = 'PUBLISHED'
        AND p.latitude IS NOT NULL
        AND p.longitude IS NOT NULL
        AND ST_DWithin(
          geography(ST_MakePoint(p.longitude::double precision, p.latitude::double precision)),
          geography(ST_MakePoint(${longitude}::double precision, ${latitude}::double precision)),
          ${radiusKm * 1000}
        )
      ORDER BY p.created_at DESC
      LIMIT ${pageSize} OFFSET ${(page - 1) * pageSize}
    `;
    return posts;
  }

  async searchByTag(tag: string, page = 1, pageSize = 20) {
    return this.prisma.post.findMany({
      where: {
        status: 'PUBLISHED',
        tags: { array_contains: [tag] },
      },
      include: {
        author: { select: { id: true, username: true, nickname: true, avatar: true } },
      },
      skip: (page - 1) * pageSize,
      take: pageSize,
      orderBy: { createdAt: 'desc' },
    });
  }
}
