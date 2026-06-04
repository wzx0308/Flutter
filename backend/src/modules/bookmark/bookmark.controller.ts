import { Controller, Get, Post, Delete, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { BookmarkService } from './bookmark.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('收藏')
@Controller()
export class BookmarkController {
  constructor(private readonly bookmarkService: BookmarkService) {}

  @ApiBearerAuth()
  @Post('posts/:postId/bookmark')
  @ApiOperation({ summary: '收藏/取消收藏帖子' })
  toggleBookmark(
    @CurrentUser('id') userId: string,
    @Param('postId') postId: string,
  ) {
    return this.bookmarkService.toggleBookmark(userId, postId);
  }

  @ApiBearerAuth()
  @Get('users/me/bookmarks')
  @ApiOperation({ summary: '获取我的收藏列表' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'pageSize', required: false, type: Number })
  getMyBookmarks(
    @CurrentUser('id') userId: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.bookmarkService.getUserBookmarks(
      userId,
      page ? parseInt(page, 10) : 1,
      pageSize ? parseInt(pageSize, 10) : 20,
    );
  }
}
