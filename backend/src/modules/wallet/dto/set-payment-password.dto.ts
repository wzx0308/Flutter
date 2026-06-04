import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, MinLength, MaxLength } from 'class-validator';

export class SetPaymentPasswordDto {
  @ApiPropertyOptional({ description: '旧支付密码（首次设置可不传）', example: '123456' })
  @IsOptional()
  @IsString()
  oldPassword?: string;

  @ApiProperty({ description: '新支付密码（6位数字）', example: '654321' })
  @IsString()
  @MinLength(6)
  @MaxLength(6)
  newPassword: string;
}
