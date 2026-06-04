import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength, MaxLength } from 'class-validator';

export class VerifyPaymentPasswordDto {
  @ApiProperty({ description: '支付密码（6位数字）', example: '123456' })
  @IsString()
  @MinLength(6)
  @MaxLength(6)
  password: string;
}
