import { Body, Controller, Get, Patch, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UsersService } from './users.service';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateMeDto } from './dto/update-me.dto';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  getMe(@CurrentUser() userId?: string) {
    return this.usersService.getMe(userId);
  }

  @Patch('me')
  updateMe(@CurrentUser() userId: string | undefined, @Body() dto: UpdateMeDto) {
    return this.usersService.updateMe(userId, dto);
  }

  @Post('change-password')
  changePassword(
    @CurrentUser() userId: string | undefined,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.usersService.changePassword(userId, dto);
  }
}
