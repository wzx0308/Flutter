import { Controller, Get, Query, Param } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { SearchService } from './search.service';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('搜索与发现')
@Controller()
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get('search')
  @Public()
  @ApiOperation({ summary: '综合搜索' })
  async search(
    @Query('q') query: string,
    @Query('type') type?: string,
    @Query('page') page?: string,
  ) {
    return this.searchService.search(query, type, Number(page) || 1);
  }

  @Get('search/trending')
  @Public()
  @ApiOperation({ summary: '热门搜索词' })
  async trending() {
    return this.searchService.getTrending();
  }

  @Get('discover/recommended')
  @Public()
  @ApiOperation({ summary: '推荐内容' })
  async recommended(@CurrentUser('id') userId: string, @Query('page') page?: string) {
    return this.searchService.getRecommended(userId, Number(page) || 1);
  }

  @Get('discover/nearby')
  @Public()
  @ApiOperation({ summary: '附近动态' })
  async nearby(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radius') radius?: string,
    @Query('page') page?: string,
  ) {
    return this.searchService.getNearby(
      Number(lat), Number(lng), Number(radius) || 10, Number(page) || 1,
    );
  }

  @Get('tags/:tag/posts')
  @Public()
  @ApiOperation({ summary: '话题下的帖子' })
  async tagPosts(@Param('tag') tag: string, @Query('page') page?: string) {
    return this.searchService.searchByTag(tag, Number(page) || 1);
  }
}
