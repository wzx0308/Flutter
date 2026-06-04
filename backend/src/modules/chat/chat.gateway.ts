import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { forwardRef, Inject } from '@nestjs/common';
import { ChatService } from './chat.service';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { CallService } from '../call/call.service';

@WebSocketGateway({ cors: { origin: '*' }, namespace: '/chat' })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private onlineUsers = new Map<string, string>(); // userId -> socketId

  constructor(
    private chatService: ChatService,
    private prisma: PrismaService,
    private jwtService: JwtService,
    @Inject(forwardRef(() => CallService))
    private callService: CallService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth?.token || client.handshake.headers?.authorization?.replace('Bearer ', '');
      if (!token) {
        client.disconnect();
        return;
      }
      const payload = await this.jwtService.verifyAsync(token);
      const userId = payload.sub;
      client.data.userId = userId;
      this.onlineUsers.set(userId, client.id);
      client.join(`user:${userId}`);
      this.server.emit('user:status', { userId, online: true });
    } catch {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.data.userId;
    if (userId) {
      this.onlineUsers.delete(userId);
      this.server.emit('user:status', { userId, online: false });
    }
  }

  @SubscribeMessage('chat:send')
  async handleSend(@ConnectedSocket() client: Socket, @MessageBody() data: { conversationId: string; content: string; type?: string; mediaUrl?: string }) {
    const senderId = client.data.userId;
    if (!senderId) return;

    const { allowed } = await this.chatService.canSendMessage(data.conversationId, senderId);
    if (!allowed) {
      client.emit('chat:restricted', { message: '互相关注后可继续聊天' });
      return;
    }

    const message = await this.chatService.saveMessage(data.conversationId, senderId, data.content, data.type, data.mediaUrl);

    // Get conversation with member user data for broadcasting
    const conv = await this.prisma.conversation.findUnique({
      where: { id: data.conversationId },
      include: {
        members: {
          include: { user: { select: { id: true, nickname: true, username: true, avatar: true } } },
        },
      },
    });

    const allMembers = conv?.members || [];

    for (const member of allMembers) {
      const otherMembers = allMembers.filter((m) => m.userId !== member.userId);
      const other = otherMembers[0]?.user;

      this.server.to(`user:${member.userId}`).emit('chat:receive', {
        id: message.id,
        conversationId: data.conversationId,
        senderId,
        content: message.content,
        type: message.type,
        mediaUrl: message.mediaUrl,
        senderName: message.sender?.nickname || message.sender?.username,
        senderAvatar: message.sender?.avatar,
        createdAt: message.createdAt,
        // Include other member info for chat list display
        otherMemberName: other?.nickname || other?.username || '',
        otherMemberAvatar: other?.avatar || null,
      });
    }
  }

  @SubscribeMessage('chat:typing')
  async handleTyping(@ConnectedSocket() client: Socket, @MessageBody() data: { conversationId: string }) {
    const senderId = client.data.userId;
    if (!senderId) return;
    const members = await this.chatService.getConversationMembers(data.conversationId);
    for (const member of members) {
      if (member.userId !== senderId) {
        this.server.to(`user:${member.userId}`).emit('chat:typing', { conversationId: data.conversationId, userId: senderId });
      }
    }
  }

  @SubscribeMessage('chat:read')
  async handleRead(@ConnectedSocket() client: Socket, @MessageBody() data: { conversationId: string }) {
    const userId = client.data.userId;
    if (!userId) return;
    await this.chatService.markRead(data.conversationId, userId);
    const members = await this.chatService.getConversationMembers(data.conversationId);
    for (const member of members) {
      if (member.userId !== userId) {
        this.server.to(`user:${member.userId}`).emit('chat:read:ack', { conversationId: data.conversationId, userId });
      }
    }
  }

  isUserOnline(userId: string): boolean {
    return this.onlineUsers.has(userId);
  }

  sendNotification(userId: string, notification: any) {
    this.server.to(`user:${userId}`).emit('notification:new', notification);
  }

  sendNotificationCount(userId: string, count: number) {
    this.server.to(`user:${userId}`).emit('notification:count', { count });
  }

  sendToUser(userId: string, event: string, data: any) {
    this.server.to(`user:${userId}`).emit(event, data);
  }

  // ═══════════════ Call Signaling ═══════════════

  @SubscribeMessage('call:invite')
  async handleCallInvite(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { userId: string; type: string; conversationId?: string },
  ) {
    const callerId = client.data.userId;
    if (!callerId) return;

    const session = await this.callService.createCallSession(
      callerId,
      data.userId,
      data.type as 'VOICE' | 'VIDEO',
      data.conversationId,
    );

    // 获取呼叫者信息
    const caller = await this.prisma.user.findUnique({
      where: { id: callerId },
      select: { id: true, nickname: true, username: true, avatar: true },
    });

    // 通知被呼叫方
    const calleeOnline = this.isUserOnline(data.userId);
    if (calleeOnline) {
      this.server.to(`user:${data.userId}`).emit('call:incoming', {
        callId: session.id,
        channelId: session.channelId,
        callerId,
        callerName: caller?.nickname || caller?.username || '',
        callerAvatar: caller?.avatar || '',
        type: data.type,
        conversationId: data.conversationId,
      });
    }

    // 返回给呼叫方
    client.emit('call:created', {
      callId: session.id,
      channelId: session.channelId,
      calleeOnline,
    });

    // 30 秒超时未接听
    setTimeout(async () => {
      const current = await this.callService.getCallSession(session.id);
      if (current && current.status === 'RINGING') {
        await this.callService.timeoutCall(session.id);
        this.server.to(`user:${callerId}`).emit('call:timeout', { callId: session.id });
        if (calleeOnline) {
          this.server.to(`user:${data.userId}`).emit('call:timeout', { callId: session.id });
        }
        // 保存未接通话消息
        await this.callService.saveCallMessage({ ...current, status: 'TIMEOUT' });
      }
    }, 30000);
  }

  @SubscribeMessage('call:accept')
  async handleCallAccept(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { callId: string },
  ) {
    const userId = client.data.userId;
    if (!userId) return;

    const session = await this.callService.acceptCall(data.callId);
    if (!session) return;

    // 通知呼叫方
    this.server.to(`user:${session.callerId}`).emit('call:accepted', {
      callId: session.id,
      channelId: session.channelId,
    });
  }

  @SubscribeMessage('call:reject')
  async handleCallReject(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { callId: string },
  ) {
    const userId = client.data.userId;
    if (!userId) return;

    const session = await this.callService.rejectCall(data.callId);
    if (!session) return;

    // 通知呼叫方
    this.server.to(`user:${session.callerId}`).emit('call:rejected', {
      callId: session.id,
    });

    // 保存拒绝通话消息
    await this.callService.saveCallMessage({ ...session, status: 'REJECTED' });
  }

  @SubscribeMessage('call:hangup')
  async handleCallHangup(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { callId: string; duration?: number },
  ) {
    const userId = client.data.userId;
    if (!userId) return;

    const session = await this.callService.endCall(data.callId, data.duration);
    if (!session) return;

    // 通知双方
    this.server.to(`user:${session.callerId}`).emit('call:ended', {
      callId: session.id,
      duration: session.duration,
    });
    this.server.to(`user:${session.calleeId}`).emit('call:ended', {
      callId: session.id,
      duration: session.duration,
    });

    // 保存通话记录消息
    await this.callService.saveCallMessage({ ...session, status: 'ENDED' });
  }
}
