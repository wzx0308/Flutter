import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  async createConversation(userId: string, type: string, userIds: string[], name?: string) {
    if (type === 'PRIVATE' && userIds.length === 1) {
      const existing = await this.prisma.conversation.findFirst({
        where: {
          type: 'PRIVATE',
          AND: [
            { members: { some: { userId } } },
            { members: { some: { userId: userIds[0] } } },
          ],
        },
        include: {
          members: { include: { user: { select: { id: true, nickname: true, avatar: true, username: true } } } },
          messages: { orderBy: { createdAt: 'desc' }, take: 1, include: { sender: { select: { id: true, nickname: true } } } },
        },
      });
      if (existing) return this.formatConversation(existing, userId);
    }

    const allMembers = [...new Set([userId, ...userIds])];
    const conversation = await this.prisma.conversation.create({
      data: {
        type: type as any,
        name: type === 'GROUP' ? name : null,
        members: {
          create: allMembers.map((uid, i) => ({
            userId: uid,
            role: uid === userId ? 'OWNER' : 'MEMBER',
          })),
        },
      },
      include: { members: { include: { user: { select: { id: true, nickname: true, avatar: true, username: true } } } } },
    });
    return this.formatConversation(conversation, userId);
  }

  async getConversations(userId: string) {
    const members = await this.prisma.conversationMember.findMany({
      where: { userId },
      include: {
        conversation: {
          include: {
            members: { include: { user: { select: { id: true, nickname: true, avatar: true, username: true } } } },
            messages: { orderBy: { createdAt: 'desc' }, take: 1, include: { sender: { select: { id: true, nickname: true } } } },
          },
        },
      },
      orderBy: [
        { isPinned: 'desc' },
        { conversation: { updatedAt: 'desc' } },
      ],
    });
    return Promise.all(members.map((m) => this.formatConversation(m.conversation, userId, m.unreadCount, m.isPinned, m.isMuted)));
  }

  async getConversation(conversationId: string, userId: string) {
    const conv = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        members: { include: { user: { select: { id: true, nickname: true, avatar: true, username: true } } } },
        messages: { orderBy: { createdAt: 'desc' }, take: 1, include: { sender: { select: { id: true, nickname: true } } } },
      },
    });
    if (!conv) throw new NotFoundException('会话不存在');
    const member = conv.members.find((m) => m.userId === userId);
    if (!member) throw new ForbiddenException('无权访问此会话');
    return this.formatConversation(conv, userId, member.unreadCount);
  }

  async getMessages(conversationId: string, userId: string, page = 1, pageSize = 50) {
    const member = await this.prisma.conversationMember.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    if (!member) throw new ForbiddenException('无权访问此会话');

    const messages = await this.prisma.message.findMany({
      where: { conversationId },
      include: { sender: { select: { id: true, nickname: true, avatar: true, username: true } } },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * pageSize,
      take: pageSize,
    });
    return messages.reverse();
  }

  async saveMessage(conversationId: string, senderId: string, content: string, type = 'TEXT', mediaUrl?: string) {
    const validTypes = ['TEXT', 'IMAGE', 'FILE', 'SYSTEM', 'TRANSFER', 'VOICE'];
    const msgType = validTypes.includes(type) ? type : 'TEXT';
    const message = await this.prisma.message.create({
      data: { conversationId, senderId, content, type: msgType as any, mediaUrl },
      include: { sender: { select: { id: true, nickname: true, avatar: true, username: true } } },
    });
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });
    const otherMembers = await this.prisma.conversationMember.findMany({
      where: { conversationId, userId: { not: senderId } },
    });
    await Promise.all(
      otherMembers.map((m) =>
        this.prisma.conversationMember.update({
          where: { id: m.id },
          data: { unreadCount: { increment: 1 } },
        }),
      ),
    );
    return message;
  }

  async markRead(conversationId: string, userId: string) {
    await this.prisma.conversationMember.updateMany({
      where: { conversationId, userId },
      data: { unreadCount: 0, lastReadAt: new Date() },
    });
  }

  async togglePin(conversationId: string, userId: string) {
    const member = await this.prisma.conversationMember.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    if (!member) throw new ForbiddenException('无权操作此会话');
    const updated = await this.prisma.conversationMember.update({
      where: { id: member.id },
      data: { isPinned: !member.isPinned },
    });
    return { isPinned: updated.isPinned };
  }

  async markUnread(conversationId: string, userId: string) {
    const member = await this.prisma.conversationMember.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    if (!member) throw new ForbiddenException('无权操作此会话');
    await this.prisma.conversationMember.update({
      where: { id: member.id },
      data: { unreadCount: 1 },
    });
    return { success: true };
  }

  async deleteConversation(conversationId: string, userId: string) {
    const member = await this.prisma.conversationMember.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    if (!member) throw new ForbiddenException('无权访问此会话');
    await this.prisma.conversationMember.delete({ where: { id: member.id } });
    const remaining = await this.prisma.conversationMember.count({ where: { conversationId } });
    if (remaining === 0) {
      await this.prisma.message.deleteMany({ where: { conversationId } });
      await this.prisma.conversation.delete({ where: { id: conversationId } });
    }
  }

  async getConversationMembers(conversationId: string) {
    return this.prisma.conversationMember.findMany({
      where: { conversationId },
      select: { userId: true },
    });
  }

  async canSendMessage(conversationId: string, senderId: string): Promise<{ allowed: boolean }> {
    const members = await this.prisma.conversationMember.findMany({
      where: { conversationId },
      select: { userId: true },
    });
    const otherUserId = members.find((m) => m.userId !== senderId)?.userId;
    if (!otherUserId) return { allowed: true };

    const [f1, f2] = await Promise.all([
      this.prisma.follow.findUnique({
        where: { followerId_followingId: { followerId: senderId, followingId: otherUserId } },
      }),
      this.prisma.follow.findUnique({
        where: { followerId_followingId: { followerId: otherUserId, followingId: senderId } },
      }),
    ]);
    if (!!f1 && !!f2) return { allowed: true };

    const count = await this.prisma.message.count({
      where: { conversationId, senderId },
    });
    return { allowed: count < 1 };
  }

  private async formatConversation(conv: any, userId: string, unreadCount = 0, isPinned = false, isMuted = false) {
    if (!conv || !conv.members) {
      throw new Error('Invalid conversation data');
    }
    const otherMembers = conv.members?.filter((m: any) => m.userId !== userId) || [];
    const lastMessage = conv.messages?.[0] || null;

    let isMutualFollow = false;
    if (conv.type === 'PRIVATE' && otherMembers[0]?.userId) {
      const otherUserId = otherMembers[0].userId;
      const [f1, f2] = await Promise.all([
        this.prisma.follow.findUnique({
          where: { followerId_followingId: { followerId: userId, followingId: otherUserId } },
        }),
        this.prisma.follow.findUnique({
          where: { followerId_followingId: { followerId: otherUserId, followingId: userId } },
        }),
      ]);
      isMutualFollow = !!f1 && !!f2;
    }

    const otherUser = otherMembers[0]?.user;
    const conversationName = conv.type === 'PRIVATE'
      ? (otherUser?.nickname || otherUser?.username || 'Unknown')
      : (conv.name || 'Group');

    return {
      id: String(conv.id ?? ''),
      type: String(conv.type ?? ''),
      name: String(conversationName),
      avatar: conv.type === 'PRIVATE' ? (otherUser?.avatar || null) : (conv.avatar || null),
      members: (conv.members || []).map((m: any) => ({
        id: String(m.user?.id ?? ''),
        nickname: m.user?.nickname ?? null,
        username: m.user?.username ?? null,
        avatar: m.user?.avatar ?? null,
        role: String(m.role ?? ''),
      })),
      lastMessage: lastMessage
        ? {
            id: String(lastMessage.id ?? ''),
            content: String(lastMessage.content ?? ''),
            type: String(lastMessage.type ?? ''),
            senderId: String(lastMessage.senderId ?? ''),
            senderName: String(lastMessage.sender?.nickname ?? ''),
            createdAt: lastMessage.createdAt instanceof Date ? lastMessage.createdAt.toISOString() : String(lastMessage.createdAt ?? ''),
          }
        : null,
      unreadCount: Number(unreadCount),
      updatedAt: conv.updatedAt instanceof Date ? conv.updatedAt.toISOString() : String(conv.updatedAt ?? ''),
      isMutualFollow: Boolean(isMutualFollow),
      isPinned: Boolean(isPinned),
      isMuted: Boolean(isMuted),
    };
  }
}
