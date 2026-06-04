import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class ChangePasswordDto {
  @ApiProperty({ description: '原密码', example: 'oldpassword' })
  @IsString()
  oldPassword: string;

  @ApiProperty({ description: '新密码（至少6位）', example: 'newpassword' })
  @IsString()
  @MinLength(6, { message: '新密码至少6位' })
  newPassword: string;
}
