import { IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateReportDto {
  @ApiProperty({ enum: ['POST', 'COMMENT', 'USER'], description: '举报目标类型' })
  @IsEnum(['POST', 'COMMENT', 'USER'])
  targetType: string;

  @ApiProperty({ description: '被举报对象ID' })
  @IsUUID()
  targetId: string;

  @ApiProperty({ enum: ['SPAM', 'ABUSE', 'ILLEGAL', 'OTHER'], description: '举报原因' })
  @IsEnum(['SPAM', 'ABUSE', 'ILLEGAL', 'OTHER'])
  reason: string;

  @ApiPropertyOptional({ description: '详细描述' })
  @IsOptional()
  @IsString()
  description?: string;
}
