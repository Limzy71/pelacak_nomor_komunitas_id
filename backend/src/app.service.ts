import { Injectable } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  async getHello() {
    const userCount = await this.prisma.user.count();
    const phoneCount = await this.prisma.phoneNumber.count();
    const tagCount = await this.prisma.tag.count();

    return {
      message: 'Selamat datang di Phone Reputation Check API! 🛡️',
      status: 'OK',
      database: 'Terhubung via Prisma 7 (@prisma/adapter-pg)',
      statistics: {
        users: userCount,
        phoneNumbers: phoneCount,
        tags: tagCount,
      },
    };
  }
}
