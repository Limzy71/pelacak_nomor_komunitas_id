import { Module } from '@nestjs/common';
import { PrismaModule } from './prisma/prisma.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PhoneLookupModule } from './phone-lookup/phone-lookup.module';

@Module({
  imports: [PrismaModule, PhoneLookupModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
