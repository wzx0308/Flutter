import { IsString, IsOptional, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateCommentDto {
  @ApiProperty({ description: '评论内容', maxLength: 500 })
  @IsString()
  @MaxLength(500)
  content: string;

  @ApiPropertyOptional({ description: '父评论ID（回复时使用）' })
  @IsOptional()
  @IsString()
  parentId?: string;
}
