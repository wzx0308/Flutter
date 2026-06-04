import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SensitiveWordFilter } from '../../common/filters/sensitive-word.filter';
import { CreateCommentDto } from './dto/create-comment.dto';
import { CommentStatus } from '@prisma/client';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class CommentService {
  constructor(
    private prisma: PrismaService,
    private sensitiveFilter: SensitiveWordFilter,
    private notificationService: NotificationService,
  ) {}

  async create(userId: string, postId: string, dto: CreateCommentDto) {
    this.sensitiveFilter.validate(dto.content);

    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('帖子不存在');

    if (dto.parentId) {
      const parent = await this.prisma.comment.findUnique({ where: { id: dto.parentId } });
      if (!parent || parent.postId !== postId) {
        throw new NotFoundException('父评论不存在');
      }
    }

    const [comment] = await this.prisma.$transaction([
      this.prisma.comment.create({
        data: {
          content: dto.content,
          postId,
          authorId: userId,
          parentId: dto.parentId || null,
        },
        include: {
          author: {
            select: { id: true, username: true, nickname: true, avatar: true },
          },
        },
      }),
      this.prisma.post.update({
        where: { id: postId },
        data: { commentCount: { increment: 1 } },
      }),
    ]);

    if (post.authorId !== userId) {
      this.notificationService.createAndNotify({
        userId: post.authorId,
        actorId: userId,
        type: 'COMMENT',
        targetType: 'Post',
        targetId: postId,
        content: dto.content,
      });
    }

    return comment;
  }

  async findByPost(postId: string, page = 1, pageSize = 20) {
    const skip = (page - 1) * pageSize;

    const [comments, total] = await Promise.all([
      this.prisma.comment.findMany({
        where: { postId, parentId: null, status: CommentStatus.PUBLISHED },
        include: {
          author: {
            select: { id: true, username: true, nickname: true, avatar: true },
          },
          replies: {
            where: { status: CommentStatus.PUBLISHED },
            include: {
              author: {
                select: { id: true, username: true, nickname: true, avatar: true },
              },
            },
            orderBy: { createdAt: 'asc' },
            take: 3,
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: pageSize,
      }),
      this.prisma.comment.count({
        where: { postId, parentId: null, status: CommentStatus.PUBLISHED },
      }),
    ]);

    return {
      list: comments,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }

  async remove(id: string, userId: string) {
    const comment = await this.prisma.comment.findUnique({ where: { id } });
    if (!comment) throw new NotFoundException('评论不存在');
    if (comment.authorId !== userId) throw new ForbiddenException('无权删除该评论');

    const [updated] = await this.prisma.$transaction([
      this.prisma.comment.update({
        where: { id },
        data: { status: CommentStatus.DELETED },
      }),
      this.prisma.post.update({
        where: { id: comment.postId },
        data: { commentCount: { decrement: 1 } },
      }),
    ]);

    return updated;
  }
}
