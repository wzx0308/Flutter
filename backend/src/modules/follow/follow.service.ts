import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class FollowService {
  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
  ) {}

  private userBriefSelect = {
    id: true,
    username: true,
    nickname: true,
    avatar: true,
    bio: true,
    followerCount: true,
    followingCount: true,
  };

  async toggleFollow(followerId: string, followingId: string) {
    if (followerId === followingId) {
      throw new BadRequestException('不能关注自己');
    }

    const target = await this.prisma.user.findUnique({ where: { id: followingId } });
    if (!target) throw new NotFoundException('用户不存在');

    const existing = await this.prisma.follow.findUnique({
      where: { followerId_followingId: { followerId, followingId } },
    });

    if (existing) {
      const [, follower, following] = await this.prisma.$transaction([
        this.prisma.follow.delete({ where: { id: existing.id } }),
        this.prisma.user.update({
          where: { id: followerId },
          data: { followingCount: { decrement: 1 } },
        }),
        this.prisma.user.update({
          where: { id: followingId },
          data: { followerCount: { decrement: 1 } },
        }),
      ]);
      return {
        followed: false,
        followerFollowingCount: follower.followingCount,
        targetFollowerCount: following.followerCount,
      };
    }

    const [, follower, following] = await this.prisma.$transaction([
      this.prisma.follow.create({ data: { followerId, followingId } }),
      this.prisma.user.update({
        where: { id: followerId },
        data: { followingCount: { increment: 1 } },
      }),
      this.prisma.user.update({
        where: { id: followingId },
        data: { followerCount: { increment: 1 } },
      }),
    ]);

    this.notificationService.createAndNotify({
      userId: followingId,
      actorId: followerId,
      type: 'FOLLOW',
      targetType: 'User',
      targetId: followerId,
    });

    return {
      followed: true,
      followerFollowingCount: follower.followingCount,
      targetFollowerCount: following.followerCount,
    };
  }

  async getFollowers(userId: string, page = 1, pageSize = 20) {
    const skip = (page - 1) * pageSize;

    const [follows, total] = await Promise.all([
      this.prisma.follow.findMany({
        where: { followingId: userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: pageSize,
      }),
      this.prisma.follow.count({ where: { followingId: userId } }),
    ]);

    const followerIds = follows.map((f) => f.followerId);
    const users = await this.prisma.user.findMany({
      where: { id: { in: followerIds } },
      select: this.userBriefSelect,
    });

    const userMap = new Map(users.map((u) => [u.id, u]));
    const list = follows.map((f) => ({
      ...userMap.get(f.followerId),
      followedAt: f.createdAt,
    }));

    return {
      list,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }

  async getFollowing(userId: string, page = 1, pageSize = 20) {
    const skip = (page - 1) * pageSize;

    const [follows, total] = await Promise.all([
      this.prisma.follow.findMany({
        where: { followerId: userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: pageSize,
      }),
      this.prisma.follow.count({ where: { followerId: userId } }),
    ]);

    const followingIds = follows.map((f) => f.followingId);
    const users = await this.prisma.user.findMany({
      where: { id: { in: followingIds } },
      select: this.userBriefSelect,
    });

    const userMap = new Map(users.map((u) => [u.id, u]));
    const list = follows.map((f) => ({
      ...userMap.get(f.followingId),
      followedAt: f.createdAt,
    }));

    return {
      list,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }

  async isFollowing(followerId: string, followingId: string) {
    const follow = await this.prisma.follow.findUnique({
      where: { followerId_followingId: { followerId, followingId } },
    });
    return { followed: !!follow };
  }

  async isMutualFollow(userId1: string, userId2: string): Promise<boolean> {
    const [f1, f2] = await Promise.all([
      this.prisma.follow.findUnique({
        where: { followerId_followingId: { followerId: userId1, followingId: userId2 } },
      }),
      this.prisma.follow.findUnique({
        where: { followerId_followingId: { followerId: userId2, followingId: userId1 } },
      }),
    ]);
    return !!f1 && !!f2;
  }

  async getFriends(userId: string, page = 1, pageSize = 20) {
    const skip = (page - 1) * pageSize;

    const myFollowing = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });
    const followingIds = myFollowing.map((f) => f.followingId);
    if (followingIds.length === 0) {
      return { list: [], total: 0, page, pageSize, totalPages: 0 };
    }

    const [mutuals, total] = await Promise.all([
      this.prisma.follow.findMany({
        where: {
          followerId: { in: followingIds },
          followingId: userId,
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: pageSize,
      }),
      this.prisma.follow.count({
        where: {
          followerId: { in: followingIds },
          followingId: userId,
        },
      }),
    ]);

    const friendIds = mutuals.map((f) => f.followerId);
    const users = await this.prisma.user.findMany({
      where: { id: { in: friendIds } },
      select: this.userBriefSelect,
    });

    const userMap = new Map(users.map((u) => [u.id, u]));
    const list = mutuals.map((f) => ({
      ...userMap.get(f.followerId),
      friendsSince: f.createdAt,
    }));

    return {
      list,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }
}
