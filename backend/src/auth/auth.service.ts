import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

export interface JwtPayload {
  sub: string;   // nomor HP E.164, misalnya +6281234567890
  phone: string; // sama dengan sub, untuk kemudahan akses
  iat?: number;
  exp?: number;
}

@Injectable()
export class AuthService {
  constructor(private readonly jwtService: JwtService) {}

  /**
   * Membuat JWT token untuk pengguna yang telah memverifikasi nomor HP via OTP.
   * Token berlaku 30 hari.
   */
  createToken(phoneNumber: string): string {
    const payload: JwtPayload = { sub: phoneNumber, phone: phoneNumber };
    return this.jwtService.sign(payload);
  }

  /**
   * Verifikasi token JWT dan kembalikan payload-nya.
   */
  verifyToken(token: string): JwtPayload {
    return this.jwtService.verify<JwtPayload>(token);
  }
}
