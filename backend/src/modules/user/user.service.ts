import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UserService {
  constructor(private prisma: PrismaService) {}

  private userSelect = {
    id: true,
    username: true,
    nickname: true,
    avatar: true,
    bio: true,
    email: true,
    phone: true,
    gender: true,
    birthday: true,
    location: true,
    role: true,
    status: true,
    followerCount: true,
    followingCount: true,
    postCount: true,
    createdAt: true,
    updatedAt: true,
  };

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: this.userSelect,
    });
    if (!user) throw new NotFoundException('用户不存在');
    return user;
  }

  async getUserById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        username: true,
        nickname: true,
        avatar: true,
        bio: true,
        location: true,
        role: true,
        followerCount: true,
        followingCount: true,
        postCount: true,
        createdAt: true,
      },
    });
    if (!user) throw new NotFoundException('用户不存在');
    return user;
  }

  async updateMe(userId: string, dto: UpdateUserDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        nickname: dto.nickname,
        avatar: dto.avatar,
        bio: dto.bio,
        gender: dto.gender as any,
        birthday: dto.birthday ? new Date(dto.birthday + 'T00:00:00') : undefined,
        location: dto.location,
      },
      select: this.userSelect,
    });
  }

  async searchUsers(keyword: string, currentUserId: string, page = 1, pageSize = 20) {
    const where = {
      AND: [
        { status: 'NORMAL' as any },
        { id: { not: currentUserId } },
        {
          OR: [
            { username: { contains: keyword, mode: 'insensitive' as any } },
            { nickname: { contains: keyword, mode: 'insensitive' as any } },
          ],
        },
      ],
    };
    const [list, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        select: {
          id: true,
          username: true,
          nickname: true,
          avatar: true,
          bio: true,
          followerCount: true,
          followingCount: true,
        },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.user.count({ where }),
    ]);
    return { list, total };
  }
}
