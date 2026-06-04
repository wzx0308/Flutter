import { Module } from '@nestjs/common';
import { WalletController } from './wallet.controller';
import { WalletService } from './wallet.service';
import { AlipayService } from './alipay.service';

@Module({
  controllers: [WalletController],
  providers: [WalletService, AlipayService],
  exports: [WalletService],
})
export class WalletModule {}
