import { Controller, Get, Post, Body, Param, Query, Req, Res, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import type { Request, Response } from 'express';
import { WalletService } from './wallet.service';
import { AlipayService } from './alipay.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { CreateRechargeDto } from './dto/create-recharge.dto';
import { SetPaymentPasswordDto } from './dto/set-payment-password.dto';
import { VerifyPaymentPasswordDto } from './dto/verify-payment-password.dto';

@ApiTags('钱包')
@ApiBearerAuth()
@Controller('wallet')
export class WalletController {
  constructor(
    private readonly walletService: WalletService,
    private readonly alipayService: AlipayService,
  ) {}

  @Get('balance')
  @ApiOperation({ summary: '获取钱包余额' })
  getBalance(@CurrentUser('id') userId: string) {
    return this.walletService.getBalance(userId);
  }

  @Post('recharge')
  @ApiOperation({ summary: '创建充值订单（返回支付宝二维码）' })
  createRecharge(@CurrentUser('id') userId: string, @Body() dto: CreateRechargeDto) {
    return this.walletService.createRechargeOrder(userId, dto.amount);
  }

  @Post('simulate-pay/:tradeNo')
  @ApiOperation({ summary: '【沙箱模拟】模拟支付成功，直接到账' })
  simulatePay(@Param('tradeNo') tradeNo: string) {
    return this.walletService.simulatePaySuccess(tradeNo);
  }

  @Get('query-order/:tradeNo')
  @ApiOperation({ summary: '查询订单支付状态（轮询用）' })
  async queryOrder(@Param('tradeNo') tradeNo: string) {
    return this.walletService.queryAndConfirmOrder(tradeNo);
  }

  @Public()
  @Post('alipay/notify')
  @HttpCode(200)
  @ApiOperation({ summary: '支付宝异步回调（无需鉴权）' })
  async alipayNotify(@Req() req: Request, @Res() res: Response) {
    const params = req.body as Record<string, string>;

    if (!params.sign) {
      return res.send('failure');
    }

    const verified = this.alipayService.verifyNotify(params);
    if (!verified) {
      return res.send('failure');
    }

    const result = await this.walletService.handleAlipayNotify(params);
    return res.send(result);
  }

  @Get('transactions')
  @ApiOperation({ summary: '获取充值/消费记录' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'pageSize', required: false, example: 20 })
  getTransactions(
    @CurrentUser('id') userId: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.walletService.getTransactions(
      userId,
      page ? parseInt(page, 10) : 1,
      pageSize ? parseInt(pageSize, 10) : 20,
    );
  }

  // ========== 支付密码 ==========

  @Get('payment-password/status')
  @ApiOperation({ summary: '查询是否已设置支付密码' })
  getPaymentPasswordStatus(@CurrentUser('id') userId: string) {
    return this.walletService.getPaymentPasswordStatus(userId);
  }

  @Post('payment-password/set')
  @ApiOperation({ summary: '设置/修改支付密码' })
  setPaymentPassword(@CurrentUser('id') userId: string, @Body() dto: SetPaymentPasswordDto) {
    return this.walletService.setPaymentPassword(userId, dto.oldPassword, dto.newPassword);
  }

  @Post('payment-password/verify')
  @ApiOperation({ summary: '验证支付密码' })
  verifyPaymentPassword(@CurrentUser('id') userId: string, @Body() dto: VerifyPaymentPasswordDto) {
    return this.walletService.verifyPaymentPassword(userId, dto.password);
  }
}
