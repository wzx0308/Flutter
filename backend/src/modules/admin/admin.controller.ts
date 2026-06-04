import { Controller, Get, Patch, Body, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('管理后台')
@ApiBearerAuth()
@Roles('ADMIN')
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard')
  @ApiOperation({ summary: '仪表盘统计' })
  async dashboard() {
    return this.adminService.getDashboard();
  }

  @Get('users')
  @ApiOperation({ summary: '用户列表' })
  async getUsers(
    @Query('page') page?: string,
    @Query('keyword') keyword?: string,
    @Query('status') status?: string,
  ) {
    return this.adminService.getUsers(Number(page) || 1, 20, keyword, status);
  }

  @Patch('users/:id/status')
  @ApiOperation({ summary: '更新用户状态（封禁/解封）' })
  async updateUserStatus(@Param('id') id: string, @Body('status') status: string) {
    return this.adminService.updateUserStatus(id, status);
  }

  @Patch('users/:id/role')
  @ApiOperation({ summary: '更新用户角色' })
  async updateUserRole(@Param('id') id: string, @Body('role') role: string) {
    return this.adminService.updateUserRole(id, role);
  }

  @Get('posts')
  @ApiOperation({ summary: '帖子列表' })
  async getPosts(
    @Query('page') page?: string,
    @Query('status') status?: string,
    @Query('keyword') keyword?: string,
  ) {
    return this.adminService.getPosts(Number(page) || 1, 20, status, keyword);
  }

  @Patch('posts/:id/status')
  @ApiOperation({ summary: '更新帖子状态（审核/隐藏/删除）' })
  async updatePostStatus(@Param('id') id: string, @Body('status') status: string) {
    return this.adminService.updatePostStatus(id, status);
  }

  @Get('reports')
  @ApiOperation({ summary: '举报列表' })
  async getReports(@Query('page') page?: string, @Query('status') status?: string) {
    return this.adminService.getReports(Number(page) || 1, 20, status);
  }

  @Patch('reports/:id/status')
  @ApiOperation({ summary: '更新举报状态' })
  async updateReportStatus(@Param('id') id: string, @Body('status') status: string) {
    return this.adminService.updateReportStatus(id, status);
  }
}
