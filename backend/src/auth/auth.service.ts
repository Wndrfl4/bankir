import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto, RegisterRoleDto } from './dto/register.dto';

type AuthTokens = {
  accessToken: string;
  refreshToken: string;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto): Promise<{ userId: string } & AuthTokens> {
    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [{ username: dto.username }, { email: dto.email }],
      },
    });

    if (existingUser) {
      throw new ConflictException('User with this username or email already exists');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const role = dto.role === RegisterRoleDto.ADMIN ? UserRole.ADMIN : UserRole.USER;

    const user = await this.prisma.user.create({
      data: {
        username: dto.username,
        email: dto.email,
        passwordHash,
        role,
        accounts: {
          create: {
            iban: `KZ${Date.now()}${Math.floor(Math.random() * 1000)}`,
            balance: 0,
            isPrimary: true,
          },
        },
      },
    });

    const tokens = await this.issueTokens(user.id);
    return {
      userId: user.id,
      ...tokens,
    };
  }

  async login(dto: LoginDto): Promise<{ userId: string; role: UserRole } & AuthTokens> {
    const user = await this.prisma.user.findUnique({
      where: {
        username: dto.username,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isValidPassword = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValidPassword) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const tokens = await this.issueTokens(user.id);
    return {
      userId: user.id,
      role: user.role,
      ...tokens,
    };
  }

  async refresh(dto: RefreshTokenDto): Promise<AuthTokens> {
    let payload: { sub: string };

    try {
      payload = await this.jwtService.verifyAsync<{ sub: string }>(dto.refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET ?? 'dev-refresh-secret',
      });
    } catch {
      throw new UnauthorizedException('Refresh token is invalid or expired');
    }

    const savedTokens = await this.prisma.refreshToken.findMany({
      where: {
        userId: payload.sub,
        expiresAt: {
          gt: new Date(),
        },
      },
    });

    if (savedTokens.length == 0) {
      throw new UnauthorizedException('Refresh token is invalid or expired');
    }

    let matchedTokenId: string | null = null;

    for (const savedToken of savedTokens) {
      const isValidToken = await bcrypt.compare(dto.refreshToken, savedToken.tokenHash);
      if (isValidToken) {
        matchedTokenId = savedToken.id;
        break;
      }
    }

    if (!matchedTokenId) {
      throw new UnauthorizedException('Refresh token is invalid or expired');
    }

    await this.prisma.refreshToken.delete({
      where: {
        id: matchedTokenId,
      },
    });

    return this.issueTokens(payload.sub);
  }

  private async issueTokens(userId: string): Promise<AuthTokens> {
    const payload = { sub: userId };
    const accessToken = await this.jwtService.signAsync(payload, {
      secret: process.env.JWT_ACCESS_SECRET ?? 'dev-access-secret',
      expiresIn: process.env.JWT_ACCESS_TTL ?? '15m',
    });
    const refreshToken = await this.jwtService.signAsync(payload, {
      secret: process.env.JWT_REFRESH_SECRET ?? 'dev-refresh-secret',
      expiresIn: process.env.JWT_REFRESH_TTL ?? '7d',
    });
    const tokenHash = await bcrypt.hash(refreshToken, 10);

    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    return {
      accessToken,
      refreshToken,
    };
  }
}
