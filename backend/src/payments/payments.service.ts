import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { TransactionStatus, TransactionType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PayBillDto } from './dto/pay-bill.dto';
import { TopUpDto } from './dto/top-up.dto';
import { TransferDto } from './dto/transfer.dto';

@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService) {}

  async transfer(userId: string | undefined, dto: TransferDto) {
    if (!userId) {
      throw new UnauthorizedException('User session is missing');
    }

    if (dto.fromCard === dto.toCard) {
      throw new BadRequestException('Cannot transfer to the same card');
    }

    const fromUser = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { accounts: true },
    });

    if (!fromUser) {
      throw new NotFoundException('User not found');
    }

    const sourceAccount = fromUser.accounts.find((account) => account.isPrimary);

    if (!sourceAccount) {
      throw new NotFoundException('Primary account was not found');
    }

    if (Number(sourceAccount.balance) < dto.amount) {
      throw new BadRequestException('Insufficient balance');
    }

    await this.prisma.$transaction([
      this.prisma.account.update({
        where: { id: sourceAccount.id },
        data: { balance: { decrement: dto.amount } },
      }),
      this.prisma.transaction.create({
        data: {
          type: TransactionType.TRANSFER,
          status: TransactionStatus.SUCCESS,
          amount: dto.amount,
          note: dto.note ? `${dto.note} | to:${dto.toCard}` : `to:${dto.toCard}`,
          sourceUserId: fromUser.id,
          sourceAccountId: sourceAccount.id,
        },
      }),
    ]);

    return { success: true };
  }

  async topUp(userId: string | undefined, dto: TopUpDto) {
    if (!userId) {
      throw new UnauthorizedException('User session is missing');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { accounts: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const primaryAccount = user.accounts.find((account) => account.isPrimary);
    if (!primaryAccount) {
      throw new NotFoundException('Primary account was not found');
    }

    await this.prisma.$transaction([
      this.prisma.account.update({
        where: { id: primaryAccount.id },
        data: { balance: { increment: dto.amount } },
      }),
      this.prisma.transaction.create({
        data: {
          type: TransactionType.TOP_UP,
          status: TransactionStatus.SUCCESS,
          amount: dto.amount,
          provider: dto.provider,
          note: dto.phone,
          destinationUserId: user.id,
          destinationAccountId: primaryAccount.id,
        },
      }),
    ]);

    return { success: true };
  }

  async payBill(userId: string | undefined, dto: PayBillDto) {
    if (!userId) {
      throw new UnauthorizedException('User session is missing');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { accounts: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const primaryAccount = user.accounts.find((account) => account.isPrimary);
    if (!primaryAccount) {
      throw new NotFoundException('Primary account was not found');
    }

    if (Number(primaryAccount.balance) < dto.amount) {
      throw new BadRequestException('Insufficient balance');
    }

    await this.prisma.$transaction([
      this.prisma.account.update({
        where: { id: primaryAccount.id },
        data: { balance: { decrement: dto.amount } },
      }),
      this.prisma.transaction.create({
        data: {
          type: TransactionType.BILL_PAYMENT,
          status: TransactionStatus.SUCCESS,
          amount: dto.amount,
          billCategory: dto.category,
          note: dto.account,
          sourceUserId: user.id,
          sourceAccountId: primaryAccount.id,
        },
      }),
    ]);

    return { success: true };
  }
}
