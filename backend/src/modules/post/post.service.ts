import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SensitiveWordFilter } from '../../common/filters/sensitive-word.filter';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';
import { QueryPostDto } from './dto/query-post.dto';

@Injectable()
export class PostService {
  constructor(private prisma: PrismaService, private sensitiveFilter: SensitiveWordFilter) {}

  private authorSelect = {
    id: true,
    username: true,
    nickname: true,
    avatar: true,
  };

  private postInclude = {
    author: { select: this.authorSelect },
  };

  async create(userId: string, dto: CreatePostDto) {
    if (dto.content) this.sensitiveFilter.validate(dto.content);
    if (dto.title) this.sensitiveFilter.validate(dto.title);

    const post = await this.prisma.post.create({
      data: {
        authorId: userId,
        content: dto.content,
        title: dto.title,
        type: (dto.type as any) ?? 'POST',
        images: dto.images ?? undefined,
        tags: dto.tags ?? undefined,
        locationName: dto.locationName,
        latitude: dto.latitude,
        longitude: dto.longitude,
      },
      include: this.postInclude,
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: { postCount: { increment: 1 } },
    });

    return post;
  }

  async findAll(query: QueryPostDto, userId?: string) {
    const { page = 1, pageSize = 20, type, authorId, tag } = query;
    const skip = (page - 1) * pageSize;

    const where: any = { status: 'PUBLISHED' };
    if (type) where.type = type;
    if (authorId) where.authorId = authorId;
    if (tag) {
      where.tags = { array_contains: [tag] };
    }

    const [items, total] = await Promise.all([
      this.prisma.post.findMany({
        where,
        include: this.postInclude,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip,
        take: pageSize,
      }),
      this.prisma.post.count({ where }),
    ]);

    const enriched = userId ? await this.enrichPosts(items, userId) : items;

    return {
      items: enriched,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }

  async findOne(id: string, userId?: string) {
    const post = await this.prisma.post.findUnique({
      where: { id },
      include: this.postInclude,
    });
    if (!post || post.status === 'DELETED') {
      throw new NotFoundException('帖子不存在');
    }
    if (!userId) return post;
    const [like, bookmark] = await Promise.all([
      this.prisma.like.findUnique({ where: { userId_postId: { userId, postId: id } } }),
      this.prisma.bookmark.findUnique({ where: { userId_postId: { userId, postId: id } } }),
    ]);
    return { ...post, isLiked: !!like, isBookmarked: !!bookmark };
  }

  private async enrichPosts(posts: any[], userId: string) {
    const postIds = posts.map((p) => p.id);
    const [likes, bookmarks] = await Promise.all([
      this.prisma.like.findMany({ where: { userId, postId: { in: postIds } }, select: { postId: true } }),
      this.prisma.bookmark.findMany({ where: { userId, postId: { in: postIds } }, select: { postId: true } }),
    ]);
    const likedSet = new Set(likes.map((l) => l.postId));
    const bookmarkedSet = new Set(bookmarks.map((b) => b.postId));
    return posts.map((p) => ({
      ...p,
      isLiked: likedSet.has(p.id),
      isBookmarked: bookmarkedSet.has(p.id),
    }));
  }

  async update(id: string, userId: string, dto: UpdatePostDto) {
    const post = await this.prisma.post.findUnique({ where: { id } });
    if (!post || post.status === 'DELETED') {
      throw new NotFoundException('帖子不存在');
    }
    if (post.authorId !== userId) {
      throw new ForbiddenException('只能编辑自己的帖子');
    }

    return this.prisma.post.update({
      where: { id },
      data: {
        content: dto.content,
        title: dto.title,
        type: dto.type as any,
        images: dto.images ?? undefined,
        tags: dto.tags ?? undefined,
        locationName: dto.locationName,
        latitude: dto.latitude,
        longitude: dto.longitude,
      },
      include: this.postInclude,
    });
  }

  async remove(id: string, userId: string) {
    const post = await this.prisma.post.findUnique({ where: { id } });
    if (!post || post.status === 'DELETED') {
      throw new NotFoundException('帖子不存在');
    }
    if (post.authorId !== userId) {
      throw new ForbiddenException('只能删除自己的帖子');
    }

    await this.prisma.post.update({
      where: { id },
      data: { status: 'DELETED' },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: { postCount: { decrement: 1 } },
    });

    return { message: '删除成功' };
  }

  async getUserPosts(userId: string, query: QueryPostDto) {
    return this.findAll({ ...query, authorId: userId });
  }
}
