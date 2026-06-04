import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  async getDashboard() {
    const [totalUsers, totalPosts, totalComments, totalReports, newUsersToday, newPostsToday, pendingReports] = await Promise.all([
      this.prisma.user.count({ where: { status: { not: 'DELETED' } } }),
      this.prisma.post.count({ where: { status: { not: 'DELETED' } } }),
      this.prisma.comment.count({ where: { status: { not: 'DELETED' } } }),
      this.prisma.report.count(),
      this.prisma.user.count({ where: { createdAt: { gte: new Date(new Date().setHours(0, 0, 0, 0)) } } }),
      this.prisma.post.count({ where: { createdAt: { gte: new Date(new Date().setHours(0, 0, 0, 0)) } } }),
      this.prisma.report.count({ where: { status: 'PENDING' } }),
    ]);
    return { totalUsers, totalPosts, totalComments, totalReports, newUsersToday, newPostsToday, pendingReports };
  }

  // === 用户管理 ===
  async getUsers(page = 1, pageSize = 20, keyword?: string, status?: string) {
    const where: any = {};
    if (status) where.status = status;
    if (keyword) {
      where.OR = [
        { username: { contains: keyword, mode: 'insensitive' } },
        { nickname: { contains: keyword, mode: 'insensitive' } },
        { email: { contains: keyword, mode: 'insensitive' } },
      ];
    }
    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        select: {
          id: true, username: true, nickname: true, avatar: true, email: true, phone: true,
          role: true, status: true, followerCount: true, followingCount: true, postCount: true, createdAt: true,
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.user.count({ where }),
    ]);
    return { users, total, page, pageSize };
  }

  async updateUserStatus(userId: string, status: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('用户不存在');
    return this.prisma.user.update({ where: { id: userId }, data: { status: status as any } });
  }

  async updateUserRole(userId: string, role: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('用户不存在');
    return this.prisma.user.update({ where: { id: userId }, data: { role: role as any } });
  }

  // === 内容管理 ===
  async getPosts(page = 1, pageSize = 20, status?: string, keyword?: string) {
    const where: any = {};
    if (status) where.status = status;
    if (keyword) {
      where.OR = [
        { content: { contains: keyword, mode: 'insensitive' } },
        { title: { contains: keyword, mode: 'insensitive' } },
      ];
    }
    const [posts, total] = await Promise.all([
      this.prisma.post.findMany({
        where,
        include: { author: { select: { id: true, username: true, nickname: true, avatar: true } } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.post.count({ where }),
    ]);
    return { posts, total, page, pageSize };
  }

  async updatePostStatus(postId: string, status: string) {
    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post) throw new NotFoundException('帖子不存在');
    return this.prisma.post.update({ where: { id: postId }, data: { status: status as any } });
  }

  // === 举报管理 ===
  async getReports(page = 1, pageSize = 20, status?: string) {
    const where: any = {};
    if (status) where.status = status;
    const [reports, total] = await Promise.all([
      this.prisma.report.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.report.count({ where }),
    ]);
    return { reports, total, page, pageSize };
  }

  async updateReportStatus(reportId: string, status: string) {
    return this.prisma.report.update({ where: { id: reportId }, data: { status: status as any } });
  }
}
