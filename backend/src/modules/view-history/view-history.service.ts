import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ViewHistoryService {
  constructor(private prisma: PrismaService) {}

  private postInclude = {
    author: { select: { id: true, username: true, nickname: true, avatar: true } },
  };

  async recordView(userId: string, postId: string) {
    await this.prisma.viewHistory.upsert({
      where: { userId_postId: { userId, postId } },
      update: { viewedAt: new Date() },
      create: { userId, postId },
    });
    return { success: true };
  }

  async getUserHistory(userId: string, page = 1, pageSize = 20) {
    const skip = (page - 1) * pageSize;

    const [history, total] = await Promise.all([
      this.prisma.viewHistory.findMany({
        where: { userId },
        orderBy: { viewedAt: 'desc' },
        skip,
        take: pageSize,
        include: { post: { include: this.postInclude } },
      }),
      this.prisma.viewHistory.count({ where: { userId } }),
    ]);

    const list = history.map((h) => h.post);

    return { list, total, page, pageSize, totalPages: Math.ceil(total / pageSize) };
  }

  async clearHistory(userId: string) {
    await this.prisma.viewHistory.deleteMany({ where: { userId } });
    return { success: true };
  }
}
