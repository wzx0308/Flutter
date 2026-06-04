import { Controller, Get, Query, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { CallService } from './call.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('通话')
@ApiBearerAuth()
@Controller('calls')
export class CallController {
  constructor(private callService: CallService) {}

  @Get('token')
  @ApiOperation({ summary: '获取 Agora RTC Token' })
  @ApiQuery({ name: 'channelName', description: '频道名称' })
  getToken(@CurrentUser('id') userId: string, @Query('channelName') channelName: string) {
    const token = this.callService.generateToken(userId, channelName);
    return { token, appId: this.callService['config'].get<string>('agora.appId') };
  }

  @Get('history')
  @ApiOperation({ summary: '通话记录列表' })
  @ApiQuery({ name: 'page', required: false })
  @ApiQuery({ name: 'limit', required: false })
  getHistory(
    @CurrentUser('id') userId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.callService.getCallHistory(
      userId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }
}
