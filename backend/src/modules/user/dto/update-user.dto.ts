import { IsString, IsOptional, IsEnum, IsDateString, MaxLength, IsNumber } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateUserDto {
  @ApiPropertyOptional({ description: '昵称' })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  nickname?: string;

  @ApiPropertyOptional({ description: '头像URL' })
  @IsOptional()
  @IsString()
  @MaxLength(256)
  avatar?: string;

  @ApiPropertyOptional({ description: '个人简介' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;

  @ApiPropertyOptional({ description: '性别', enum: ['MALE', 'FEMALE', 'UNKNOWN'] })
  @IsOptional()
  @IsEnum(['MALE', 'FEMALE', 'UNKNOWN'])
  gender?: string;

  @ApiPropertyOptional({ description: '生日', example: '2000-01-01' })
  @IsOptional()
  @IsDateString()
  birthday?: string;

  @ApiPropertyOptional({ description: '所在地' })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  location?: string;
}
