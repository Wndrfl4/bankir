import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PayBillDto } from './dto/pay-bill.dto';
import { TopUpDto } from './dto/top-up.dto';
import { TransferDto } from './dto/transfer.dto';
import { PaymentsService } from './payments.service';

@Controller('payments')
@UseGuards(JwtAuthGuard)
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('transfer')
  transfer(@CurrentUser() userId: string | undefined, @Body() dto: TransferDto) {
    return this.paymentsService.transfer(userId, dto);
  }

  @Post('top-up')
  topUp(@CurrentUser() userId: string | undefined, @Body() dto: TopUpDto) {
    return this.paymentsService.topUp(userId, dto);
  }

  @Post('bills')
  payBill(@CurrentUser() userId: string | undefined, @Body() dto: PayBillDto) {
    return this.paymentsService.payBill(userId, dto);
  }
}
