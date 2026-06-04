import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SendMessageDto {
  @ApiProperty({ description: '消息内容' })
  @IsString()
  content: string;

  @ApiPropertyOptional({ enum: ['TEXT', 'IMAGE', 'FILE'], default: 'TEXT' })
  @IsOptional()
  @IsEnum(['TEXT', 'IMAGE', 'FILE'])
  type?: string;

  @ApiPropertyOptional({ description: '媒体文件URL' })
  @IsOptional()
  @IsString()
  mediaUrl?: string;
}
