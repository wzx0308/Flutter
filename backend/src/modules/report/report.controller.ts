import { Controller, Get, Post, Patch, Body, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ReportService } from './report.service';
import { CreateReportDto } from './dto/create-report.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('举报')
@ApiBearerAuth()
@Controller('reports')
export class ReportController {
  constructor(private readonly reportService: ReportService) {}

  @Post()
  @ApiOperation({ summary: '提交举报' })
  async create(@CurrentUser('id') userId: string, @Body() dto: CreateReportDto) {
    return this.reportService.create(userId, dto.targetType, dto.targetId, dto.reason, dto.description);
  }

  @Get()
  @ApiOperation({ summary: '举报列表（管理）' })
  async findAll(@Query('page') page?: string, @Query('status') status?: string) {
    return this.reportService.findAll(Number(page) || 1, 20, status);
  }

  @Patch(':id/status')
  @ApiOperation({ summary: '更新举报状态（管理）' })
  async updateStatus(@Param('id') id: string, @Body('status') status: string) {
    return this.reportService.updateStatus(id, status);
  }
}
