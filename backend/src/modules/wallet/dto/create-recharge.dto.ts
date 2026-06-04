import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, Min, Max } from 'class-validator';

export class CreateRechargeDto {
  @ApiProperty({ description: '充值金额（元）', example: 10.00, minimum: 0.01, maximum: 5000 })
  @IsNumber()
  @Min(0.01)
  @Max(5000)
  amount: number;
}
