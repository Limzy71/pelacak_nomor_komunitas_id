import { Module } from '@nestjs/common';
import { PhoneLookupController } from './phone-lookup.controller';
import { PhoneLookupService } from './phone-lookup.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [PhoneLookupController],
  providers: [PhoneLookupService],
})
export class PhoneLookupModule {}
