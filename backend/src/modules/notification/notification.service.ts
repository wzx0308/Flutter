import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ChatGateway } from '../chat/chat.gateway';

@Injectable()
export class NotificationService {
  constructor(
    private prisma: PrismaService,
    private chatGateway: ChatGateway,
  ) {}

  async create(params: {
    userId: string;
    actorId: string;
    type: string;
    targetType?: string;
    targetId?: string;
    content?: string;
  }) {
    if (params.userId === params.actorId) return null;

    return this.prisma.notification.create({
      data: {
        userId: params.userId,
        actorId: params.actorId,
        type: params.type as any,
        targetType: params.targetType,
        targetId: params.targetId,
        content: params.content,
      },
    });
  }

  async createAndNotify(params: {
    userId: string;
    actorId: string;
    type: string;
    targetType?: string;
    targetId?: string;
    content?: string;
  }) {
    const notification = await this.create(params);
    if (notification) {
      const count = await this.getUnreadCount(params.userId);
      this.chatGateway.sendNotification(params.userId, notification);
      this.chatGateway.sendNotificationCount(params.userId, count.count);
    }
    return notification;
  }

  async getNotifications(userId: string, page = 1, pageSize = 20) {
    const skip = (page - 1) * pageSize;
    const [notifications, total] = await Promise.all([
      this.prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: pageSize,
        include: {
          actor: { select: { id: true, username: true, nickname: true, avatar: true } },
        },
      }),
      this.prisma.notification.count({ where: { userId } }),
    ]);
    return {
      list: notifications,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }

  async getUnreadCount(userId: string) {
    const count = await this.prisma.notification.count({
      where: { userId, isRead: false },
    });
    return { count };
  }

  async markAsRead(userId: string, notificationId?: string) {
    if (notificationId) {
      await this.prisma.notification.updateMany({
        where: { id: notificationId, userId },
        data: { isRead: true },
      });
    } else {
      await this.prisma.notification.updateMany({
        where: { userId, isRead: false },
        data: { isRead: true },
      });
    }
    return { success: true };
  }
}
