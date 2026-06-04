import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';

export class GenerateTokenDto {
  @ApiProperty({ description: 'Agora 频道名称' })
  @IsString()
  @IsNotEmpty()
  channelName: string;
}
