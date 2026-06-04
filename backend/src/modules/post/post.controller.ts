import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import type { Request } from 'express';
import { PostService } from './post.service';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';
import { QueryPostDto } from './dto/query-post.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

@ApiTags('帖子')
@ApiBearerAuth()
@Controller('posts')
export class PostController {
  constructor(
    private readonly postService: PostService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  private extractUserId(req: Request): string | undefined {
    try {
      const auth = req.headers.authorization;
      if (!auth?.startsWith('Bearer ')) return undefined;
      const token = auth.slice(7);
      const payload = this.jwtService.verify(token, {
        secret: this.configService.get('jwt.secret'),
      });
      return payload.sub || payload.id;
    } catch {
      return undefined;
    }
  }

  @Post()
  @ApiOperation({ summary: '创建帖子' })
  create(@CurrentUser('id') userId: string, @Body() dto: CreatePostDto) {
    return this.postService.create(userId, dto);
  }

  @Public()
  @Get()
  @ApiOperation({ summary: '获取帖子列表' })
  findAll(@Query() query: QueryPostDto, @Req() req: Request) {
    const userId = this.extractUserId(req);
    return this.postService.findAll(query, userId);
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: '获取帖子详情' })
  findOne(@Param('id') id: string, @Req() req: Request) {
    const userId = this.extractUserId(req);
    return this.postService.findOne(id, userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: '更新帖子' })
  update(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: UpdatePostDto,
  ) {
    return this.postService.update(id, userId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: '删除帖子' })
  remove(@Param('id') id: string, @CurrentUser('id') userId: string) {
    return this.postService.remove(id, userId);
  }
}
