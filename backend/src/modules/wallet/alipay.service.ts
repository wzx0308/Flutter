import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AlipaySdk } from 'alipay-sdk';

@Injectable()
export class AlipayService {
  private readonly sdk: InstanceType<typeof AlipaySdk>;
  private readonly logger = new Logger(AlipayService.name);

  constructor(private config: ConfigService) {
    this.sdk = new AlipaySdk({
      appId: this.config.get('ALIPAY_APP_ID')!,
      privateKey: this.config.get('ALIPAY_PRIVATE_KEY')!,
      alipayPublicKey: this.config.get('ALIPAY_PUBLIC_KEY'),
      gateway: this.config.get('ALIPAY_GATEWAY'),
      signType: (this.config.get('ALIPAY_SIGN_TYPE') as 'RSA2') || 'RSA2',
    });
  }

  async createTradePayOrder(params: {
    tradeNo: string;
    amount: string;
    subject: string;
    body?: string;
  }) {
    const notifyUrl = this.config.get<string>('ALIPAY_NOTIFY_URL');
    this.logger.log(`调用支付宝预下单: tradeNo=${params.tradeNo}, amount=${params.amount}, notifyUrl=${notifyUrl}`);

    const result = await this.sdk.exec('alipay.trade.precreate', {
      bizContent: {
        out_trade_no: params.tradeNo,
        total_amount: params.amount,
        subject: params.subject,
        body: params.body || params.subject,
      },
      notifyUrl,
    });
    this.logger.log(`支付宝预下单结果: ${JSON.stringify(result)}`);
    return result;
  }

  async queryTrade(tradeNo: string) {
    const result = await this.sdk.exec('alipay.trade.query', {
      bizContent: {
        out_trade_no: tradeNo,
      },
    });
    return result;
  }

  async closeTrade(tradeNo: string) {
    const result = await this.sdk.exec('alipay.trade.close', {
      bizContent: {
        out_trade_no: tradeNo,
      },
    });
    return result;
  }

  verifyNotify(params: Record<string, string>): boolean {
    return this.sdk.checkNotifySign(params);
  }
}
