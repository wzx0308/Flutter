import { Controller, Get, Post, Patch, Delete, Body, Param, Query, Logger } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('聊天')
@ApiBearerAuth()
@Controller('conversations')
export class ChatController {
  private readonly logger = new Logger(ChatController.name);
  constructor(private readonly chatService: ChatService) {}

  @Post()
  @ApiOperation({ summary: '创建会话' })
  async create(@CurrentUser('id') userId: string, @Body() dto: CreateConversationDto) {
    try {
      return await this.chatService.createConversation(userId, dto.type, dto.userIds, dto.name);
    } catch (error) {
      this.logger.error(`createConversation failed: ${error.message}`, error.stack);
      throw error;
    }
  }

  @Get()
  @ApiOperation({ summary: '会话列表' })
  async findAll(@CurrentUser('id') userId: string) {
    return this.chatService.getConversations(userId);
  }

  @Get(':id')
  @ApiOperation({ summary: '会话详情' })
  async findOne(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.chatService.getConversation(id, userId);
  }

  @Get(':id/messages')
  @ApiOperation({ summary: '历史消息' })
  async getMessages(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.chatService.getMessages(id, userId, Number(page) || 1, Number(pageSize) || 50);
  }

  @Patch(':id/pin')
  @ApiOperation({ summary: '切换置顶' })
  async togglePin(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.chatService.togglePin(id, userId);
  }

  @Patch(':id/unread')
  @ApiOperation({ summary: '标记为未读' })
  async markUnread(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.chatService.markUnread(id, userId);
  }

  @Patch(':id/read')
  @ApiOperation({ summary: '标记已读' })
  async markRead(@CurrentUser('id') userId: string, @Param('id') id: string) {
    await this.chatService.markRead(id, userId);
    return { success: true };
  }

  @Delete(':id')
  @ApiOperation({ summary: '删除会话' })
  async remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    await this.chatService.deleteConversation(id, userId);
    return { success: true };
  }
}
