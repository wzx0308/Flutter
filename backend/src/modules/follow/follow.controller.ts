import { Controller, Get, Post, Delete, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { FollowService } from './follow.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('关注')
@Controller('users/:id')
export class FollowController {
  constructor(private readonly followService: FollowService) {}

  @ApiBearerAuth()
  @Post('follow')
  @ApiOperation({ summary: '关注用户' })
  follow(@CurrentUser('id') userId: string, @Param('id') targetId: string) {
    return this.followService.toggleFollow(userId, targetId);
  }

  @ApiBearerAuth()
  @Delete('follow')
  @ApiOperation({ summary: '取消关注' })
  unfollow(@CurrentUser('id') userId: string, @Param('id') targetId: string) {
    return this.followService.toggleFollow(userId, targetId);
  }

  @ApiBearerAuth()
  @Get('follow-status')
  @ApiOperation({ summary: '检查是否关注了该用户' })
  @ApiQuery({ name: 'targetUserId', required: false, type: String, description: '检查该用户是否关注了:id' })
  async getFollowStatus(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Query('targetUserId') targetUserId?: string,
  ) {
    if (targetUserId) {
      return this.followService.isFollowing(targetUserId, id);
    }
    return this.followService.isFollowing(userId, id);
  }

  @ApiBearerAuth()
  @Get('mutual-follow-status')
  @ApiOperation({ summary: '检查与该用户的互相关注状态' })
  async getMutualFollowStatus(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
    const [iFollowThem, theyFollowMe] = await Promise.all([
      this.followService.isFollowing(userId, id),
      this.followService.isFollowing(id, userId),
    ]);
    return {
      iFollow: iFollowThem.followed,
      theyFollow: theyFollowMe.followed,
      isMutual: iFollowThem.followed && theyFollowMe.followed,
    };
  }

  @Public()
  @Get('followers')
  @ApiOperation({ summary: '获取粉丝列表' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'pageSize', required: false, type: Number })
  getFollowers(
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.followService.getFollowers(
      id,
      page ? parseInt(page, 10) : 1,
      pageSize ? parseInt(pageSize, 10) : 20,
    );
  }

  @Public()
  @Get('following')
  @ApiOperation({ summary: '获取关注列表' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'pageSize', required: false, type: Number })
  getFollowing(
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.followService.getFollowing(
      id,
      page ? parseInt(page, 10) : 1,
      pageSize ? parseInt(pageSize, 10) : 20,
    );
  }

  @ApiBearerAuth()
  @Get('friends')
  @ApiOperation({ summary: '获取好友列表（互相关注）' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'pageSize', required: false, type: Number })
  getFriends(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.followService.getFriends(
      id,
      page ? parseInt(page, 10) : 1,
      pageSize ? parseInt(pageSize, 10) : 20,
    );
  }
}
