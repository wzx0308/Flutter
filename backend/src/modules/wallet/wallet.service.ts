import { Injectable, BadRequestException, Logger, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AlipayService } from './alipay.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class WalletService {
  private readonly logger = new Logger(WalletService.name);

  constructor(
    private prisma: PrismaService,
    private alipayService: AlipayService,
  ) {}

  async getBalance(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { balance: true },
    });
    return { balance: Number(user.balance) };
  }

  async createRechargeOrder(userId: string, amount: number) {
    this.logger.log(`创建充值订单: userId=${userId}, amount=${amount}`);
    const tradeNo = `WALLET${Date.now()}${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
    const subject = '钱包充值';

    const transaction = await this.prisma.walletTransaction.create({
      data: {
        userId,
        amount,
        type: 'RECHARGE',
        status: 'PENDING',
        tradeNo,
        subject,
      },
    });
    this.logger.log(`订单已创建: tradeNo=${tradeNo}, transactionId=${transaction.id}`);

    try {
      // 确保金额格式正确：保留2位小数
      const amountStr = Number(amount).toFixed(2);
      this.logger.log(`支付宝预下单参数: tradeNo=${tradeNo}, amount=${amountStr}`);

      const payResult = await this.alipayService.createTradePayOrder({
        tradeNo,
        amount: amountStr,
        subject,
      });

      this.logger.log(`支付宝返回结果: ${JSON.stringify(payResult)}`);

      const resultCode = (payResult as any)?.code;
      const resultMsg = (payResult as any)?.msg;
      const qrCode = (payResult as any)?.qrCode;

      if (resultCode !== '10000' || !qrCode) {
        this.logger.error(`支付宝下单失败: code=${resultCode}, msg=${resultMsg}, full=${JSON.stringify(payResult)}`);
        // 标记订单失败
        await this.prisma.walletTransaction.update({
          where: { id: transaction.id },
          data: { status: 'FAILED' },
        });
        throw new BadRequestException(`支付宝下单失败: ${resultMsg || '未知错误'}`);
      }

      return {
        transactionId: transaction.id,
        tradeNo,
        qrCode,
        amount,
      };
    } catch (error) {
      this.logger.error(`充值下单异常: ${error.message}`, error.stack);
      // 如果订单还没标记失败，标记为失败
      try {
        await this.prisma.walletTransaction.update({
          where: { id: transaction.id },
          data: { status: 'FAILED' },
        });
      } catch (_) {}
      throw error;
    }
  }

  async handleAlipayNotify(params: Record<string, string>) {
    const tradeStatus = params.trade_status;
    const outTradeNo = params.out_trade_no;
    const totalAmount = params.total_amount;
    const alipayTradeNo = params.trade_no;

    this.logger.log(`支付宝回调: tradeNo=${outTradeNo}, status=${tradeStatus}`);

    const transaction = await this.prisma.walletTransaction.findUnique({
      where: { tradeNo: outTradeNo },
    });

    if (!transaction) {
      this.logger.warn(`未找到订单: ${outTradeNo}`);
      return 'failure';
    }

    if (transaction.status === 'SUCCESS') {
      return 'success';
    }

    if (tradeStatus === 'TRADE_SUCCESS' || tradeStatus === 'TRADE_FINISHED') {
      const expectedAmount = Number(transaction.amount);
      const actualAmount = parseFloat(totalAmount);

      if (Math.abs(expectedAmount - actualAmount) > 0.01) {
        this.logger.error(`金额不匹配: 期望=${expectedAmount}, 实际=${actualAmount}`);
        return 'failure';
      }

      await this.prisma.$transaction([
        this.prisma.walletTransaction.update({
          where: { id: transaction.id },
          data: {
            status: 'SUCCESS',
            alipayTradeNo,
          },
        }),
        this.prisma.user.update({
          where: { id: transaction.userId },
          data: { balance: { increment: transaction.amount } },
        }),
      ]);

      this.logger.log(`充值成功: userId=${transaction.userId}, amount=${transaction.amount}`);
      return 'success';
    }

    if (tradeStatus === 'TRADE_CLOSED') {
      await this.prisma.walletTransaction.update({
        where: { id: transaction.id },
        data: { status: 'CLOSED' },
      });
      return 'success';
    }

    return 'success';
  }

  async queryAndConfirmOrder(tradeNo: string) {
    const transaction = await this.prisma.walletTransaction.findUnique({
      where: { tradeNo },
    });

    if (!transaction) {
      return { status: 'NOT_FOUND', paid: false };
    }

    if (transaction.status === 'SUCCESS') {
      return { status: 'SUCCESS', paid: true };
    }

    if (transaction.status !== 'PENDING') {
      return { status: transaction.status, paid: false };
    }

    // 向支付宝查询交易状态
    try {
      const result = await this.alipayService.queryTrade(tradeNo);
      this.logger.log(`支付宝查询结果: tradeNo=${tradeNo}, result=${JSON.stringify(result)}`);

      // alipay-sdk 可能返回嵌套结构: {alipayTradeQueryResponse: {code, tradeStatus, ...}}
      const nested = (result as any)?.alipayTradeQueryResponse || result;
      const tradeStatus = nested?.tradeStatus || nested?.trade_status || (result as any)?.tradeStatus;
      this.logger.log(`轮询查询: tradeNo=${tradeNo}, tradeStatus=${tradeStatus}`);

      if (tradeStatus === 'TRADE_SUCCESS' || tradeStatus === 'TRADE_FINISHED') {
        // 支付成功，更新订单
        const alipayTradeNo = nested?.tradeNo || nested?.trade_no || (result as any)?.tradeNo || '';
        await this.prisma.$transaction([
          this.prisma.walletTransaction.update({
            where: { id: transaction.id },
            data: {
              status: 'SUCCESS',
              alipayTradeNo,
            },
          }),
          this.prisma.user.update({
            where: { id: transaction.userId },
            data: { balance: { increment: transaction.amount } },
          }),
        ]);

        this.logger.log(`轮询确认充值成功: userId=${transaction.userId}, amount=${transaction.amount}`);
        return { status: 'SUCCESS', paid: true };
      }

      return { status: 'PENDING', paid: false };
    } catch (e) {
      this.logger.error(`查询支付宝交易失败: ${e.message}`);
      return { status: 'PENDING', paid: false };
    }
  }

  async simulatePaySuccess(tradeNo: string) {
    this.logger.log(`[沙箱模拟] 模拟支付成功: tradeNo=${tradeNo}`);

    const transaction = await this.prisma.walletTransaction.findUnique({
      where: { tradeNo },
    });

    if (!transaction) {
      throw new BadRequestException('订单不存在');
    }

    if (transaction.status === 'SUCCESS') {
      return { success: true, message: '该订单已支付成功' };
    }

    if (transaction.status !== 'PENDING') {
      throw new BadRequestException(`订单状态异常: ${transaction.status}`);
    }

    await this.prisma.$transaction([
      this.prisma.walletTransaction.update({
        where: { id: transaction.id },
        data: {
          status: 'SUCCESS',
          alipayTradeNo: `SANDBOX_${Date.now()}`,
        },
      }),
      this.prisma.user.update({
        where: { id: transaction.userId },
        data: { balance: { increment: transaction.amount } },
      }),
    ]);

    this.logger.log(`[沙箱模拟] 充值成功: userId=${transaction.userId}, amount=${transaction.amount}`);
    return { success: true, message: '支付成功' };
  }

  async getTransactions(userId: string, page = 1, pageSize = 20) {
    this.logger.log(`查询交易记录: userId=${userId}, page=${page}`);
    const skip = (page - 1) * pageSize;
    const [list, total] = await Promise.all([
      this.prisma.walletTransaction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: pageSize,
      }),
      this.prisma.walletTransaction.count({ where: { userId } }),
    ]);
    this.logger.log(`交易记录: total=${total}, list.length=${list.length}`);

    // 收集 subject 中的截断 ID（8字符），用于查询用户名
    const shortIds = new Set<string>();
    for (const t of list) {
      if (t.subject) {
        const match = t.subject.match(/(?:收到|转账给|超时退回|收到退回)\s+([a-f0-9]+)/);
        if (match) shortIds.add(match[1]);
      }
    }

    // 用 LIKE 查询匹配截断ID对应的完整用户
    const userMap = new Map<string, string>();
    if (shortIds.size > 0) {
      for (const shortId of shortIds) {
        try {
          const users = await this.prisma.$queryRaw<any[]>`
            SELECT id, nickname, username FROM users
            WHERE CAST(id AS TEXT) LIKE ${shortId + '%'}
            LIMIT 1
          `;
          if (users.length > 0) {
            const u = users[0];
            userMap.set(shortId, u.nickname || u.username || '用户');
          }
        } catch (_) {}
      }
    }

    // 替换 subject 中的截断ID为用户名
    return {
      list: list.map((t) => {
        let subject = t.subject || '';
        if (subject) {
          const match = subject.match(/(收到|转账给|超时退回|收到退回)\s+([a-f0-9]+)/);
          if (match) {
            const prefix = match[1];
            const shortId = match[2];
            const name = userMap.get(shortId) || '用户';
            subject = subject.replace(`${prefix} ${shortId}`, `${prefix} ${name}`);
          }
        }
        return {
          ...t,
          amount: Number(t.amount),
          subject,
        };
      }),
      total,
      page,
      pageSize,
    };
  }

  // ========== 支付密码 ==========

  async getPaymentPasswordStatus(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { paymentPassword: true },
    });
    return { hasPassword: !!user.paymentPassword };
  }

  async setPaymentPassword(userId: string, oldPassword: string | undefined, newPassword: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { paymentPassword: true },
    });

    if (user.paymentPassword) {
      if (!oldPassword) {
        throw new BadRequestException('请提供旧密码');
      }
      const valid = bcrypt.compareSync(oldPassword, user.paymentPassword);
      if (!valid) {
        throw new UnauthorizedException('旧密码错误');
      }
    }

    const hashed = bcrypt.hashSync(newPassword, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { paymentPassword: hashed },
    });

    return { success: true, message: '支付密码设置成功' };
  }

  async verifyPaymentPassword(userId: string, password: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { paymentPassword: true },
    });

    if (!user.paymentPassword) {
      throw new BadRequestException('请先设置支付密码');
    }

    const valid = bcrypt.compareSync(password, user.paymentPassword);
    if (!valid) {
      throw new UnauthorizedException('支付密码错误');
    }

    return { success: true, message: '验证通过' };
  }
}
