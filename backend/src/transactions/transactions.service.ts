import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TransactionsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId?: string) {
    return this.prisma.transaction.findMany({
      where: userId
        ? {
            OR: [{ sourceUserId: userId }, { destinationUserId: userId }],
          }
        : undefined,
      orderBy: {
        createdAt: 'desc',
      },
      take: 50,
    });
  }
}
