import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { LoginSmsDto } from './dto/login-sms.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    if (!dto.username && !dto.email && !dto.phone) {
      throw new BadRequestException('用户名、邮箱或手机号至少填一项');
    }

    // 检查唯一性
    if (dto.username) {
      const existing = await this.prisma.user.findUnique({ where: { username: dto.username } });
      if (existing) throw new ConflictException('用户名已存在');
    }
    if (dto.email) {
      const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
      if (existing) throw new ConflictException('邮箱已注册');
    }
    if (dto.phone) {
      const existing = await this.prisma.user.findUnique({ where: { phone: dto.phone } });
      if (existing) throw new ConflictException('手机号已注册');
    }

    const hashedPassword = await bcrypt.hash(dto.password, 10);

    const user = await this.prisma.user.create({
      data: {
        username: dto.username,
        email: dto.email,
        phone: dto.phone,
        password: hashedPassword,
        nickname: dto.nickname || dto.username || `用户${Date.now().toString(36)}`,
      },
      select: {
        id: true,
        username: true,
        nickname: true,
        avatar: true,
        email: true,
        phone: true,
        role: true,
        createdAt: true,
      },
    });

    const tokens = await this.generateTokens(user.id);

    return { user, ...tokens };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { username: dto.account },
          { email: dto.account },
        ],
      },
    });

    if (!user || !user.password) {
      throw new UnauthorizedException('账号或密码错误');
    }

    if (user.status !== 'NORMAL') {
      throw new UnauthorizedException('账号状态异常');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('账号或密码错误');
    }

    const tokens = await this.generateTokens(user.id);

    return {
      user: {
        id: user.id,
        username: user.username,
        nickname: user.nickname,
        avatar: user.avatar,
        email: user.email,
        phone: user.phone,
        role: user.role,
      },
      ...tokens,
    };
  }

  async loginBySms(dto: LoginSmsDto) {
    await this.verifySmsCode(dto.phone, dto.code);

    let user = await this.prisma.user.findUnique({ where: { phone: dto.phone } });

    if (!user) {
      // 自动注册
      user = await this.prisma.user.create({
        data: {
          phone: dto.phone,
          nickname: `用户${dto.phone.slice(-4)}`,
        },
      });
    }

    if (user.status !== 'NORMAL') {
      throw new UnauthorizedException('账号状态异常');
    }

    const tokens = await this.generateTokens(user.id);

    return {
      user: {
        id: user.id,
        username: user.username,
        nickname: user.nickname,
        avatar: user.avatar,
        email: user.email,
        phone: user.phone,
        role: user.role,
      },
      ...tokens,
    };
  }

  async sendSmsCode(phone: string) {
    // 开发阶段：固定验证码 123456
    const code = process.env.NODE_ENV === 'production' ? this.generateCode() : '123456';

    // 存入数据库（实际生产环境应存入 Redis 并设置过期时间）
    await this.prisma.smsCode.create({
      data: {
        phone,
        code,
        expiresAt: new Date(Date.now() + 5 * 60 * 1000), // 5分钟有效
      },
    });

    // TODO: 实际发送短信
    // 开发阶段直接返回验证码
    return {
      message: '验证码已发送',
      ...(process.env.NODE_ENV !== 'production' && { code }),
    };
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get<string>('jwt.secret'),
      });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user || user.status !== 'NORMAL') {
        throw new UnauthorizedException('Token无效');
      }

      const tokens = await this.generateTokens(user.id);
      return tokens;
    } catch {
      throw new UnauthorizedException('Refresh Token无效或已过期');
    }
  }

  private async generateTokens(userId: string) {
    const payload = { sub: userId };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        expiresIn: this.configService.get<string>('jwt.accessExpires') as any,
      }),
      this.jwtService.signAsync(payload, {
        expiresIn: this.configService.get<string>('jwt.refreshExpires') as any,
      }),
    ]);

    return { accessToken, refreshToken };
  }

  private async verifySmsCode(phone: string, code: string) {
    const smsRecord = await this.prisma.smsCode.findFirst({
      where: {
        phone,
        used: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!smsRecord) {
      throw new BadRequestException('验证码不存在或已过期');
    }

    if (process.env.NODE_ENV === 'production' && smsRecord.code !== code) {
      throw new BadRequestException('验证码错误');
    }

    // 开发环境跳过验证码校验，或生产环境校验通过后标记已使用
    await this.prisma.smsCode.update({
      where: { id: smsRecord.id },
      data: { used: true },
    });
  }

  private generateCode(): string {
    return Math.random().toString().slice(2, 8).padStart(6, '0');
  }

  async changePassword(userId: string, oldPassword: string, newPassword: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { password: true },
    });

    if (!user.password) {
      throw new BadRequestException('账号未设置密码，请使用验证码登录');
    }

    const isOldPasswordValid = await bcrypt.compare(oldPassword, user.password);
    if (!isOldPasswordValid) {
      throw new UnauthorizedException('原密码错误');
    }

    const hashedNewPassword = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedNewPassword },
    });

    return { message: '密码修改成功' };
  }
}
