import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNumber, Min, Max, IsOptional, Matches } from 'class-validator';

export class CreateTransferDto {
  @ApiProperty({ description: '收款人用户ID', example: 'uuid' })
  @IsString()
  receiverId: string;

  @ApiProperty({ description: '转账金额（元）', example: 10, minimum: 0.01, maximum: 50000 })
  @IsNumber({ maxDecimalPlaces: 2 }, { message: '金额最多支持2位小数' })
  @Min(0.01, { message: '转账金额必须大于0' })
  @Max(50000, { message: '单笔转账不超过50000元' })
  amount: number;

  @ApiPropertyOptional({ description: '转账备注', example: '请查收' })
  @IsOptional()
  @IsString()
  remark?: string;

  @ApiProperty({ description: '支付密码（6位数字）', example: '123456' })
  @IsString()
  @Matches(/^\d{6}$/, { message: '支付密码必须为6位数字' })
  paymentPassword: string;

  @ApiPropertyOptional({ description: '会话ID（用于发送转账消息）' })
  @IsOptional()
  @IsString()
  conversationId?: string;

  @ApiPropertyOptional({ description: '幂等请求ID，防止重复提交' })
  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}
