import { Injectable, NestMiddleware, UnauthorizedException, HttpException, HttpStatus } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

// In-memory sliding window rate limiter untuk mencegah brute-force / scraping data nomor telepon
interface RateLimitRecord {
  count: number;
  resetTime: number;
}

@Injectable()
export class SecurityMiddleware implements NestMiddleware {
  private static readonly CLIENT_SECRET_HEADER = 'x-phonerep-client-key';
  private static readonly OFFICIAL_CLIENT_KEY = process.env.CLIENT_SECRET_KEY || 'phonerep-mobile-v1-secret-token-2026';
  
  // Penyimpanan memori untuk pelacakan request per IP (Maks 60 request per menit)
  private static readonly rateLimits: Map<string, RateLimitRecord> = new Map();
  private static readonly WINDOW_MS = 60 * 1000; // 1 Menit
  private static readonly MAX_REQUESTS_PER_WINDOW = 60; // 60 request / menit

  use(req: Request, res: Response, next: NextFunction) {
    // 1. Verifikasi Header Khusus Aplikasi Resmi (Client-Key Verification)
    // Mencegah pencurian data menggunakan CURL / Postman / Script Scraping dari luar aplikasi
    const clientKey = req.headers[SecurityMiddleware.CLIENT_SECRET_HEADER] || req.headers['x-phonerep-client-key'];
    
    // Izinkan CORS pre-flight OPTIONS request lolos
    if (req.method === 'OPTIONS') {
      return next();
    }

    if (clientKey !== SecurityMiddleware.OFFICIAL_CLIENT_KEY) {
      throw new UnauthorizedException(
        'Akses Ditolak: Permintaan harus berasal dari Aplikasi Resmi PhoneRep Mobile (Header Keamanan Tidak Valid).'
      );
    }

    // 2. Proteksi Rate Limiting (Anti Brute-Force & Mass Scraping)
    const clientIp = req.ip || req.socket.remoteAddress || 'unknown_ip';
    const now = Date.now();
    let record = SecurityMiddleware.rateLimits.get(clientIp);

    if (!record || now > record.resetTime) {
      record = {
        count: 1,
        resetTime: now + SecurityMiddleware.WINDOW_MS,
      };
      SecurityMiddleware.rateLimits.set(clientIp, record);
    } else {
      record.count += 1;
      if (record.count > SecurityMiddleware.MAX_REQUESTS_PER_WINDOW) {
        throw new HttpException(
          'Terlalu Banyak Permintaan (Rate Limit Exceeded). Demi keamanan data pengguna, akses sementara dibatasi.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
    }

    // Pembersihan berkala memori rate limit
    if (SecurityMiddleware.rateLimits.size > 5000) {
      for (const [ip, rec] of SecurityMiddleware.rateLimits.entries()) {
        if (now > rec.resetTime) {
          SecurityMiddleware.rateLimits.delete(ip);
        }
      }
    }

    next();
  }
}
