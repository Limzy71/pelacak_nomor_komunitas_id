import { Module } from '@nestjs/common';
import { PhoneLookupController } from './phone-lookup.controller';
import { PhoneLookupService } from './phone-lookup.service';

@Module({
  controllers: [PhoneLookupController],
  providers: [PhoneLookupService],
})
export class PhoneLookupModule {}
