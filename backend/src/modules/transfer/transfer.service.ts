import { Injectable, BadRequestException, Logger, NotFoundException, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../prisma/prisma.service';
import { ChatGateway } from '../chat/chat.gateway';
import { CreateTransferDto } from './dto/create-transfer.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class TransferService {
  private readonly logger = new Logger(TransferService.name);

  constructor(
    private prisma: PrismaService,
    private chatGateway: ChatGateway,
  ) {}

  async createTransfer(userId: string, dto: CreateTransferDto) {
    const { receiverId, amount, remark, paymentPassword, conversationId, idempotencyKey } = dto;

    if (userId === receiverId) {
      throw new BadRequestException('不能给自己转账');
    }

    // 验证金额
    const transferAmount = Math.round(amount * 100) / 100;
    if (transferAmount <= 0) {
      throw new BadRequestException('转账金额必须大于0');
    }

    // 验证支付密码
    const sender = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { paymentPassword: true },
    });

    if (!sender) {
      throw new NotFoundException('用户不存在');
    }

    if (!sender.paymentPassword) {
      throw new BadRequestException('请先设置支付密码');
    }

    const passwordValid = bcrypt.compareSync(paymentPassword, sender.paymentPassword);
    if (!passwordValid) {
      throw new UnauthorizedException('支付密码错误');
    }

    // 验证收款人存在
    const receiver = await this.prisma.user.findUnique({
      where: { id: receiverId },
      select: { id: true, status: true },
    });
    if (!receiver || receiver.status !== 'NORMAL') {
      throw new NotFoundException('收款人不存在或状态异常');
    }

    const expireAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    // 数据库事务：行锁 + 扣款 + 加钱 + 创建转账记录 + 创建流水
    const result = await this.prisma.$transaction(async (tx) => {
      // 行锁防超扣
      const senderForUpdate = await tx.$queryRaw`
        SELECT id, balance FROM users WHERE id = ${userId}::uuid FOR UPDATE
      `;
      const currentBalance = Number((senderForUpdate as any[])[0].balance);
      if (currentBalance < transferAmount) {
        throw new BadRequestException(`余额不足，当前余额 ¥${currentBalance.toFixed(2)}`);
      }

      // 幂等性检查
      if (idempotencyKey) {
        const existing = await tx.transfer.findFirst({
          where: { senderId: userId, remark: `__idem:${idempotencyKey}` },
        });
        if (existing) {
          return existing;
        }
      }

      // A 扣款
      await tx.user.update({
        where: { id: userId },
        data: { balance: { decrement: transferAmount } },
      });

      // B 加钱
      await tx.user.update({
        where: { id: receiverId },
        data: { balance: { increment: transferAmount } },
      });

      // 创建转账记录
      const transfer = await tx.transfer.create({
        data: {
          senderId: userId,
          receiverId,
          amount: transferAmount,
          remark: remark || null,
          status: 'PENDING',
          conversationId: conversationId || null,
          expireAt,
        },
      });

      // 创建转出流水
      await tx.walletTransaction.create({
        data: {
          userId,
          amount: transferAmount,
          type: 'TRANSFER_OUT',
          status: 'SUCCESS',
          tradeNo: `TF${Date.now()}${Math.random().toString(36).slice(2, 6).toUpperCase()}`,
          subject: `转账给 ${receiverId.slice(0, 8)}`,
        },
      });

      // 创建转入流水
      await tx.walletTransaction.create({
        data: {
          userId: receiverId,
          amount: transferAmount,
          type: 'TRANSFER_IN',
          status: 'SUCCESS',
          tradeNo: `TR${Date.now()}${Math.random().toString(36).slice(2, 6).toUpperCase()}`,
          subject: `收到 ${userId.slice(0, 8)} 转账`,
        },
      });

      return transfer;
    });

    this.logger.log(`转账成功: ${userId} -> ${receiverId}, 金额: ¥${transferAmount}, transferId: ${result.id}`);

    // 发送转账消息到聊天
    try {
      const messageId = await this._sendTransferMessage(userId, receiverId, result.id, transferAmount, remark ?? null, conversationId);
      // 将 messageId 关联到转账记录
      if (messageId) {
        await this.prisma.transfer.update({
          where: { id: result.id },
          data: { messageId },
        });
      }
    } catch (e) {
      this.logger.error(`发送转账消息失败: ${e.message}`);
    }

    return {
      transferId: result.id,
      amount: transferAmount,
      receiverId,
      remark,
      expireAt,
      message: '转账成功',
    };
  }

  private async _sendTransferMessage(
    senderId: string,
    receiverId: string,
    transferId: string,
    amount: number,
    remark: string | null,
    conversationId?: string,
  ) {
    // 查找或创建会话
    let convId = conversationId;
    if (!convId) {
      // 查找已有的私聊会话
      const senderMember = await this.prisma.conversationMember.findFirst({
        where: { userId: senderId, conversation: { type: 'PRIVATE' } },
        include: {
          conversation: {
            include: { members: { select: { userId: true } } },
          },
        },
      });

      if (senderMember) {
        for (const member of senderMember.conversation.members) {
          if (member.userId === receiverId) {
            convId = senderMember.conversationId;
            break;
          }
        }
      }

      // 没有找到则创建新会话
      if (!convId) {
        const conv = await this.prisma.conversation.create({
          data: {
            type: 'PRIVATE',
            members: {
              create: [
                { userId: senderId, role: 'OWNER' },
                { userId: receiverId, role: 'MEMBER' },
              ],
            },
          },
        });
        convId = conv.id;
      }
    }

    // 构建转账消息内容
    const content = JSON.stringify({
      transferId,
      amount,
      remark: remark || '',
      status: 'PENDING',
    });

    // 发送消息
    const message = await this.prisma.message.create({
      data: {
        conversationId: convId,
        senderId,
        type: 'TRANSFER',
        content,
      },
      include: {
        sender: { select: { id: true, nickname: true, username: true, avatar: true } },
      },
    });

    // 更新会话时间
    await this.prisma.conversation.update({
      where: { id: convId },
      data: { updatedAt: new Date() },
    });

    // 更新对方未读数
    await this.prisma.conversationMember.updateMany({
      where: { conversationId: convId, userId: receiverId },
      data: { unreadCount: { increment: 1 } },
    });

    // 通过 WebSocket 实时推送转账消息给会话成员
    try {
      const members = await this.prisma.conversationMember.findMany({
        where: { conversationId: convId },
      });
      for (const member of members) {
        this.chatGateway.sendToUser(member.userId, 'chat:receive', {
          id: message.id,
          conversationId: convId,
          senderId,
          content: message.content,
          type: 'TRANSFER',
          mediaUrl: null,
          senderName: message.sender?.nickname || message.sender?.username,
          senderAvatar: message.sender?.avatar,
          createdAt: message.createdAt,
        });
      }
    } catch (e) {
      this.logger.error(`WebSocket推送转账消息失败: ${e.message}`);
    }

    return message.id;
  }

  async acceptTransfer(transferId: string, userId: string) {
    const transfer = await this.prisma.transfer.findUniqueOrThrow({
      where: { id: transferId },
    });

    if (transfer.receiverId !== userId) {
      throw new ForbiddenException('只有收款人可以确认收款');
    }

    if (transfer.status !== 'PENDING') {
      throw new BadRequestException(`转账状态异常: ${transfer.status}`);
    }

    // 资金已在 createTransfer 时入账，这里只更新状态
    await this.prisma.transfer.update({
      where: { id: transferId },
      data: { status: 'ACCEPTED' },
    });

    // 更新聊天消息中的转账状态
    if (transfer.messageId) {
      try {
        const msg = await this.prisma.message.findUnique({ where: { id: transfer.messageId } });
        if (msg) {
          const content = JSON.parse(msg.content!);
          content.status = 'ACCEPTED';
          await this.prisma.message.update({
            where: { id: transfer.messageId },
            data: { content: JSON.stringify(content) },
          });
        }
      } catch (e) {
        this.logger.error(`更新转账消息状态失败: ${e.message}`);
      }
    }

    this.logger.log(`收款确认: transferId=${transferId}, receiverId=${userId}`);

    return { success: true, message: '收款成功' };
  }

  async refundTransfer(transferId: string, userId: string) {
    const transfer = await this.prisma.transfer.findUniqueOrThrow({
      where: { id: transferId },
    });

    if (transfer.receiverId !== userId) {
      throw new ForbiddenException('只有收款人可以退回');
    }

    if (transfer.status !== 'PENDING') {
      throw new BadRequestException(`转账状态异常: ${transfer.status}`);
    }

    const refundAmount = Number(transfer.amount);

    // 事务：B扣钱 + A加钱 + 更新状态 + 创建流水
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: transfer.receiverId },
        data: { balance: { decrement: refundAmount } },
      }),
      this.prisma.user.update({
        where: { id: transfer.senderId },
        data: { balance: { increment: refundAmount } },
      }),
      this.prisma.transfer.update({
        where: { id: transferId },
        data: { status: 'REFUNDED' },
      }),
      this.prisma.walletTransaction.create({
        data: {
          userId: transfer.receiverId,
          amount: refundAmount,
          type: 'REFUND',
          status: 'SUCCESS',
          tradeNo: `RB${Date.now()}${Math.random().toString(36).slice(2, 6).toUpperCase()}`,
          subject: `退回转账 ${transferId.slice(0, 8)}`,
        },
      }),
      this.prisma.walletTransaction.create({
        data: {
          userId: transfer.senderId,
          amount: refundAmount,
          type: 'REFUND',
          status: 'SUCCESS',
          tradeNo: `RA${Date.now()}${Math.random().toString(36).slice(2, 6).toUpperCase()}`,
          subject: `收到退回 ${transferId.slice(0, 8)}`,
        },
      }),
    ]);

    // 更新聊天消息中的转账状态
    if (transfer.messageId) {
      try {
        const msg = await this.prisma.message.findUnique({ where: { id: transfer.messageId } });
        if (msg) {
          const content = JSON.parse(msg.content!);
          content.status = 'REFUNDED';
          await this.prisma.message.update({
            where: { id: transfer.messageId },
            data: { content: JSON.stringify(content) },
          });
        }
      } catch (e) {
        this.logger.error(`更新转账消息状态失败: ${e.message}`);
      }
    }

    this.logger.log(`转账退回: transferId=${transferId}, amount=¥${refundAmount}`);

    return { success: true, message: '转账已退回' };
  }

  async getTransferDetail(transferId: string, userId: string) {
    const transfer = await this.prisma.transfer.findUniqueOrThrow({
      where: { id: transferId },
      include: {
        sender: { select: { id: true, nickname: true, username: true, avatar: true } },
        receiver: { select: { id: true, nickname: true, username: true, avatar: true } },
      },
    });

    if (transfer.senderId !== userId && transfer.receiverId !== userId) {
      throw new ForbiddenException('无权查看此转账');
    }

    return {
      ...transfer,
      amount: Number(transfer.amount),
    };
  }

  async getTransferList(userId: string, page = 1, pageSize = 20) {
    const skip = (page - 1) * pageSize;
    const where = {
      OR: [{ senderId: userId }, { receiverId: userId }],
    };

    const [list, total] = await Promise.all([
      this.prisma.transfer.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: pageSize,
        include: {
          sender: { select: { id: true, nickname: true, username: true, avatar: true } },
          receiver: { select: { id: true, nickname: true, username: true, avatar: true } },
        },
      }),
      this.prisma.transfer.count({ where }),
    ]);

    return {
      list: list.map((t) => ({ ...t, amount: Number(t.amount) })),
      total,
      page,
      pageSize,
    };
  }

  // ========== 定时任务：24小时自动退回 ==========

  @Cron(CronExpression.EVERY_5_MINUTES)
  async handleExpiredTransfers() {
    const expired = await this.prisma.transfer.findMany({
      where: {
        status: 'PENDING',
        expireAt: { lt: new Date() },
      },
    });

    if (expired.length === 0) return;

    this.logger.log(`发现 ${expired.length} 笔超时转账，执行自动退回`);

    for (const transfer of expired) {
      try {
        const refundAmount = Number(transfer.amount);

        await this.prisma.$transaction([
          this.prisma.user.update({
            where: { id: transfer.receiverId },
            data: { balance: { decrement: refundAmount } },
          }),
          this.prisma.user.update({
            where: { id: transfer.senderId },
            data: { balance: { increment: refundAmount } },
          }),
          this.prisma.transfer.update({
            where: { id: transfer.id },
            data: { status: 'EXPIRED' },
          }),
          this.prisma.walletTransaction.create({
            data: {
              userId: transfer.receiverId,
              amount: refundAmount,
              type: 'REFUND',
              status: 'SUCCESS',
              tradeNo: `EXP${Date.now()}${Math.random().toString(36).slice(2, 6).toUpperCase()}`,
              subject: `超时退回 ${transfer.id.slice(0, 8)}`,
            },
          }),
          this.prisma.walletTransaction.create({
            data: {
              userId: transfer.senderId,
              amount: refundAmount,
              type: 'REFUND',
              status: 'SUCCESS',
              tradeNo: `EXR${Date.now()}${Math.random().toString(36).slice(2, 6).toUpperCase()}`,
              subject: `超时退回 ${transfer.id.slice(0, 8)}`,
            },
          }),
        ]);

        this.logger.log(`超时退回成功: transferId=${transfer.id}, amount=¥${refundAmount}`);
      } catch (error) {
        this.logger.error(`超时退回失败: transferId=${transfer.id}, error=${error.message}`);
      }
    }
  }
}
