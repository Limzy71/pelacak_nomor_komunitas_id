import { Controller, Get, Post, Delete, Body, Param, Query, Headers, Ip } from '@nestjs/common';
import { PhoneLookupService } from './phone-lookup.service';
import { SyncContactsDto } from './dto/sync-contacts.dto';

@Controller('phone-lookup')
export class PhoneLookupController {
  constructor(private readonly phoneLookupService: PhoneLookupService) {}

  @Post('sync')
  async syncContacts(@Body() dto: SyncContactsDto) {
    return await this.phoneLookupService.syncContacts(dto);
  }

  @Post('tag')
  async addTag(
    @Body('phoneNumberId') phoneNumberId: string,
    @Body('labelName') labelName: string,
    @Body('userId') userId?: string,
  ) {
    return await this.phoneLookupService.createTag(phoneNumberId, labelName, userId);
  }

  @Post('vote')
  async voteTag(
    @Body('tagId') tagId: string,
    @Body('userId') userId: string,
    @Body('voteType') voteType: 'UPVOTE' | 'DOWNVOTE',
  ) {
    return await this.phoneLookupService.voteTag(tagId, userId, voteType);
  }

  @Post('send-otp')
  async sendOtp(@Body('phoneNumber') phoneNumber: string, @Body('isResend') isResend?: boolean) {
    return await this.phoneLookupService.sendOtp(phoneNumber, isResend);
  }

  @Post('verify-otp')
  async verifyOtp(
    @Body('phoneNumber') phoneNumber: string,
    @Body('code') code: string,
  ) {
    return await this.phoneLookupService.verifyOtp(phoneNumber, code);
  }

  @Get('analytics')
  async getAnalytics() {
    return await this.phoneLookupService.getAnalytics();
  }

  @Get(':number')
  async lookup(
    @Param('number') number: string,
    @Query('skipIncrement') skipIncrement?: string,
    @Headers('x-device-id') deviceId?: string,
    @Headers('x-has-contact-access') hasContactAccess?: string,
    @Ip() ip?: string,
  ) {
    return await this.phoneLookupService.lookupPhoneNumber(
      number,
      skipIncrement === 'true',
      deviceId || ip || 'unknown-device',
      hasContactAccess === 'true',
    );
  }

  @Delete('reset/:number')
  async resetNumberData(@Param('number') number: string) {
    return await this.phoneLookupService.resetPhoneNumberData(number);
  }
}
