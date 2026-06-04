import { IsArray, IsEnum, IsOptional, IsString, ArrayMinSize } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateConversationDto {
  @ApiProperty({ enum: ['PRIVATE', 'GROUP'], description: '会话类型' })
  @IsEnum(['PRIVATE', 'GROUP'])
  type: string;

  @ApiPropertyOptional({ description: '目标用户ID列表（私聊传1个，群聊传多个）' })
  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  userIds: string[];

  @ApiPropertyOptional({ description: '群名称（群聊专用）' })
  @IsOptional()
  @IsString()
  name?: string;
}
