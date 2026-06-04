import {
  IsString,
  IsOptional,
  IsEnum,
  IsArray,
  IsNumber,
  MaxLength,
  Max,
  ArrayMaxSize,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePostDto {
  @ApiPropertyOptional({ description: '帖子内容', maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  content?: string;

  @ApiPropertyOptional({ description: '文章标题', maxLength: 256 })
  @IsOptional()
  @IsString()
  @MaxLength(256)
  title?: string;

  @ApiPropertyOptional({
    description: '帖子类型',
    enum: ['POST', 'ARTICLE'],
    default: 'POST',
  })
  @IsOptional()
  @IsEnum(['POST', 'ARTICLE'])
  type?: 'POST' | 'ARTICLE';

  @ApiPropertyOptional({
    description: '图片列表',
    type: [String],
    maxItems: 9,
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(9)
  images?: string[];

  @ApiPropertyOptional({ description: '标签列表', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ description: '位置名称' })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  locationName?: string;

  @ApiPropertyOptional({ description: '纬度' })
  @IsOptional()
  @IsNumber()
  @Max(90)
  latitude?: number;

  @ApiPropertyOptional({ description: '经度' })
  @IsOptional()
  @IsNumber()
  @Max(180)
  longitude?: number;
}
