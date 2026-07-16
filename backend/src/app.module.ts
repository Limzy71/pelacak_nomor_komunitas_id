import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaModule } from './prisma/prisma.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PhoneLookupModule } from './phone-lookup/phone-lookup.module';
import { SecurityMiddleware } from './security/security.middleware';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    PrismaModule,
    PhoneLookupModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(SecurityMiddleware)
      .forRoutes('phone-lookup');
  }
}
