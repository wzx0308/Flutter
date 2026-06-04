import { Controller, Post, Delete, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { LikeService } from './like.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('点赞')
@ApiBearerAuth()
@Controller('posts/:postId/like')
export class LikeController {
  constructor(private readonly likeService: LikeService) {}

  @Post()
  @ApiOperation({ summary: '点赞帖子' })
  like(@CurrentUser('id') userId: string, @Param('postId') postId: string) {
    return this.likeService.toggleLike(userId, postId);
  }

  @Delete()
  @ApiOperation({ summary: '取消点赞' })
  unlike(@CurrentUser('id') userId: string, @Param('postId') postId: string) {
    return this.likeService.toggleLike(userId, postId);
  }
}
