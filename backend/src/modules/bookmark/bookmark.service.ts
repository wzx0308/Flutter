import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class BookmarkService {
  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
  ) {}

  private postInclude = {
    author: { select: { id: true, username: true, nickname: true, avatar: true } },
  };

  async toggleBookmark(userId: string, postId: string) {
    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('帖子不存在');

    const existing = await this.prisma.bookmark.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (existing) {
      await this.prisma.bookmark.delete({ where: { id: existing.id } });
      return { bookmarked: false };
    }

    await this.prisma.bookmark.create({ data: { userId, postId } });

    if (post.authorId !== userId) {
      this.notificationService.createAndNotify({
        userId: post.authorId,
        actorId: userId,
        type: 'BOOKMARK',
        targetType: 'Post',
        targetId: postId,
      });
    }

    return { bookmarked: true };
  }

  async getUserBookmarks(userId: string, page = 1, pageSize = 20) {
    const skip = (page - 1) * pageSize;

    const [bookmarks, total] = await Promise.all([
      this.prisma.bookmark.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: pageSize,
        include: { post: { include: this.postInclude } },
      }),
      this.prisma.bookmark.count({ where: { userId } }),
    ]);

    const list = bookmarks.map((b) => b.post);

    return { list, total, page, pageSize, totalPages: Math.ceil(total / pageSize) };
  }
}
