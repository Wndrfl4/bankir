import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateMeDto } from './dto/update-me.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId?: string) {
    if (!userId) {
      throw new UnauthorizedException('User session is missing');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        accounts: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      accounts: user.accounts,
      createdAt: user.createdAt,
    };
  }

  async updateMe(userId: string | undefined, dto: UpdateMeDto) {
    if (!userId) {
      throw new UnauthorizedException('User session is missing');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (dto.username && dto.username !== user.username) {
      const existingByUsername = await this.prisma.user.findUnique({
        where: { username: dto.username },
      });

      if (existingByUsername && existingByUsername.id !== userId) {
        throw new ConflictException('Username is already taken');
      }
    }

    if (dto.email && dto.email !== user.email) {
      const existingByEmail = await this.prisma.user.findUnique({
        where: { email: dto.email },
      });

      if (existingByEmail && existingByEmail.id !== userId) {
        throw new ConflictException('Email is already taken');
      }
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        username: dto.username,
        email: dto.email,
      },
      include: {
        accounts: true,
      },
    });

    return {
      id: updatedUser.id,
      username: updatedUser.username,
      email: updatedUser.email,
      role: updatedUser.role,
      accounts: updatedUser.accounts,
      createdAt: updatedUser.createdAt,
    };
  }

  async changePassword(userId: string | undefined, dto: ChangePasswordDto) {
    if (!userId) {
      throw new UnauthorizedException('User session is missing');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isValidPassword = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!isValidPassword) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    const newPasswordHash = await bcrypt.hash(dto.newPassword, 10);

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash: newPasswordHash,
      },
    });

    return { success: true };
  }
}
