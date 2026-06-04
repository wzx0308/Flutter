import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class LikeService {
  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
  ) {}

  async toggleLike(userId: string, postId: string) {
    const existingPost = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!existingPost) throw new NotFoundException('帖子不存在');

    const existing = await this.prisma.like.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (existing) {
      const [, updatedPost] = await this.prisma.$transaction([
        this.prisma.like.delete({ where: { id: existing.id } }),
        this.prisma.post.update({
          where: { id: postId },
          data: { likeCount: { decrement: 1 } },
        }),
      ]);
      return { liked: false, likeCount: updatedPost.likeCount };
    }

    const [, updatedPost] = await this.prisma.$transaction([
      this.prisma.like.create({ data: { userId, postId } }),
      this.prisma.post.update({
        where: { id: postId },
        data: { likeCount: { increment: 1 } },
      }),
    ]);

    if (existingPost.authorId !== userId) {
      this.notificationService.createAndNotify({
        userId: existingPost.authorId,
        actorId: userId,
        type: 'LIKE',
        targetType: 'Post',
        targetId: postId,
      });
    }

    return { liked: true, likeCount: updatedPost.likeCount };
  }

  async isLiked(userId: string, postId: string) {
    const like = await this.prisma.like.findUnique({
      where: { userId_postId: { userId, postId } },
    });
    return { liked: !!like };
  }
}
