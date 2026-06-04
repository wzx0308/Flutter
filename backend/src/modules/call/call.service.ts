import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { RtcTokenBuilder, RtcRole } from 'agora-token';

@Injectable()
export class CallService {
  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
  ) {}

  generateToken(uid: string, channelName: string): string {
    const appId = this.config.get<string>('agora.appId') || '';
    const appCertificate = this.config.get<string>('agora.appCertificate') || '';
    const expire = 3600;

    return RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid,
      RtcRole.PUBLISHER,
      expire,
      expire,
    );
  }

  generateChannelName(): string {
    const ts = Date.now().toString(36);
    const rand = Math.random().toString(36).substring(2, 8);
    return `call_${ts}_${rand}`;
  }

  async createCallSession(
    callerId: string,
    calleeId: string,
    type: 'VOICE' | 'VIDEO',
    conversationId?: string,
  ) {
    const channelId = this.generateChannelName();
    return this.prisma.callSession.create({
      data: {
        callerId,
        calleeId,
        conversationId: conversationId || null,
        type,
        channelId,
        status: 'RINGING',
      },
    });
  }

  async acceptCall(callId: string) {
    return this.prisma.callSession.update({
      where: { id: callId },
      data: {
        status: 'ACCEPTED',
        startedAt: new Date(),
      },
    });
  }

  async rejectCall(callId: string) {
    return this.prisma.callSession.update({
      where: { id: callId },
      data: { status: 'REJECTED' },
    });
  }

  async timeoutCall(callId: string) {
    return this.prisma.callSession.update({
      where: { id: callId },
      data: { status: 'TIMEOUT' },
    });
  }

  async endCall(callId: string, duration?: number) {
    return this.prisma.callSession.update({
      where: { id: callId },
      data: {
        status: 'ENDED',
        endedAt: new Date(),
        duration: duration || 0,
      },
    });
  }

  async missCall(callId: string) {
    return this.prisma.callSession.update({
      where: { id: callId },
      data: { status: 'MISSED' },
    });
  }

  async getCallSession(callId: string) {
    return this.prisma.callSession.findUnique({ where: { id: callId } });
  }

  async saveCallMessage(session: any) {
    if (!session.conversationId) return;

    const callInfo = JSON.stringify({
      callType: session.type,
      duration: session.duration || 0,
      status: session.status,
    });

    return this.prisma.message.create({
      data: {
        conversationId: session.conversationId,
        senderId: session.callerId,
        type: 'CALL',
        content: callInfo,
      },
    });
  }

  async getCallHistory(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.callSession.findMany({
        where: {
          OR: [{ callerId: userId }, { calleeId: userId }],
        },
        include: {
          caller: { select: { id: true, nickname: true, username: true, avatar: true } },
          callee: { select: { id: true, nickname: true, username: true, avatar: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.callSession.count({
        where: {
          OR: [{ callerId: userId }, { calleeId: userId }],
        },
      }),
    ]);

    return { items, total, page, limit };
  }
}
