import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class ReportService {
  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
  ) {}

  async create(reporterId: string, targetType: string, targetId: string, reason: string, description?: string) {
    const existing = await this.prisma.report.findFirst({
      where: { reporterId, targetType: targetType as any, targetId },
    });
    if (existing) throw new BadRequestException('您已举报过该内容');

    return this.prisma.report.create({
      data: {
        reporterId,
        targetType: targetType as any,
        targetId,
        reason: reason as any,
        description,
      },
    });
  }

  async findAll(page = 1, pageSize = 20, status?: string) {
    const where: any = {};
    if (status) where.status = status;
    const [reports, total] = await Promise.all([
      this.prisma.report.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.report.count({ where }),
    ]);
    return { reports, total, page, pageSize };
  }

  async updateStatus(id: string, status: string) {
    const report = await this.prisma.report.findUnique({ where: { id } });
    const updated = await this.prisma.report.update({
      where: { id },
      data: { status: status as any },
    });

    if (report && status === 'RESOLVED') {
      this.notificationService.createAndNotify({
        userId: report.reporterId,
        actorId: report.reporterId,
        type: 'REPORT_RESOLVED',
        targetType: report.targetType,
        targetId: report.targetId,
      });
    }

    return updated;
  }
}
