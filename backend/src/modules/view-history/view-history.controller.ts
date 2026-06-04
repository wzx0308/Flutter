import { Controller, Get, Post, Delete, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ViewHistoryService } from './view-history.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('浏览历史')
@Controller()
export class ViewHistoryController {
  constructor(private readonly viewHistoryService: ViewHistoryService) {}

  @ApiBearerAuth()
  @Post('posts/:postId/view')
  @ApiOperation({ summary: '记录浏览' })
  recordView(
    @CurrentUser('id') userId: string,
    @Param('postId') postId: string,
  ) {
    return this.viewHistoryService.recordView(userId, postId);
  }

  @ApiBearerAuth()
  @Get('users/me/history')
  @ApiOperation({ summary: '获取浏览历史' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'pageSize', required: false, type: Number })
  getMyHistory(
    @CurrentUser('id') userId: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.viewHistoryService.getUserHistory(
      userId,
      page ? parseInt(page, 10) : 1,
      pageSize ? parseInt(pageSize, 10) : 20,
    );
  }

  @ApiBearerAuth()
  @Delete('users/me/history')
  @ApiOperation({ summary: '清空浏览历史' })
  clearHistory(@CurrentUser('id') userId: string) {
    return this.viewHistoryService.clearHistory(userId);
  }
}
