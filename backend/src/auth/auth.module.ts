import { Module, OnModuleInit, Logger } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { JwtStrategy } from './jwt.strategy';

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      useFactory: () => {
        const secret = process.env.JWT_SECRET;
        if (!secret) {
          throw new Error(
            '[AUTH] FATAL: JWT_SECRET tidak tersedia di environment variables. Set JWT_SECRET di .env sebelum menjalankan server.',
          );
        }
        return {
          secret,
          signOptions: { expiresIn: '30d' },
        };
      },
    }),
  ],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService, JwtModule],
})
export class AuthModule implements OnModuleInit {
  private readonly logger = new Logger(AuthModule.name);

  onModuleInit() {
    if (!process.env.JWT_SECRET) {
      throw new Error(
        '[AUTH] FATAL: JWT_SECRET tidak tersedia di environment variables.',
      );
    }
    this.logger.log('AuthModule berhasil diinisialisasi.');
  }
}
