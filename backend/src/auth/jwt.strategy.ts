import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { JwtPayload } from './auth.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      throw new Error('[JWT_STRATEGY] FATAL: JWT_SECRET tidak tersedia di environment variables.');
    }
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: JwtPayload) {
    if (!payload?.sub || !payload?.phone) {
      throw new UnauthorizedException('Token tidak valid atau sudah kedaluwarsa.');
    }
    // Mengembalikan objek user yang akan di-attach ke req.user
    return { phoneNumber: payload.sub };
  }
}
