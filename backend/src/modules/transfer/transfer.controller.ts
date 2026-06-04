import { Controller, Get, Post, Body, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { TransferService } from './transfer.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CreateTransferDto } from './dto/create-transfer.dto';

@ApiTags('转账')
@ApiBearerAuth()
@Controller('transfer')
export class TransferController {
  constructor(private readonly transferService: TransferService) {}

  @Post()
  @ApiOperation({ summary: '发起转账' })
  createTransfer(@CurrentUser('id') userId: string, @Body() dto: CreateTransferDto) {
    return this.transferService.createTransfer(userId, dto);
  }

  @Post(':id/accept')
  @ApiOperation({ summary: '确认收款' })
  acceptTransfer(@Param('id') id: string, @CurrentUser('id') userId: string) {
    return this.transferService.acceptTransfer(id, userId);
  }

  @Post(':id/refund')
  @ApiOperation({ summary: '退回转账' })
  refundTransfer(@Param('id') id: string, @CurrentUser('id') userId: string) {
    return this.transferService.refundTransfer(id, userId);
  }

  @Get(':id')
  @ApiOperation({ summary: '查询转账详情' })
  getTransferDetail(@Param('id') id: string, @CurrentUser('id') userId: string) {
    return this.transferService.getTransferDetail(id, userId);
  }

  @Get('list')
  @ApiOperation({ summary: '我的转账记录' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'pageSize', required: false, example: 20 })
  getTransferList(
    @CurrentUser('id') userId: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.transferService.getTransferList(
      userId,
      page ? parseInt(page, 10) : 1,
      pageSize ? parseInt(pageSize, 10) : 20,
    );
  }
}
