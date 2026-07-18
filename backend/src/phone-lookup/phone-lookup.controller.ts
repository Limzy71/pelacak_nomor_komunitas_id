import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  Headers,
  Ip,
  UnauthorizedException,
  ForbiddenException,
  InternalServerErrorException,
  UseGuards,
  Req,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { Request } from 'express';
import { PhoneLookupService } from './phone-lookup.service';
import { SyncContactsDto } from './dto/sync-contacts.dto';
import { AuthService } from '../auth/auth.service';
import { JwtAuthGuard, OptionalJwtAuthGuard } from '../auth/jwt-auth.guard';

// Extend Request type agar TypeScript tahu req.user
interface AuthenticatedRequest extends Request {
  user?: { phoneNumber: string };
}

@Controller('phone-lookup')
export class PhoneLookupController {
  constructor(
    private readonly phoneLookupService: PhoneLookupService,
    private readonly authService: AuthService,
  ) {}

  // ============================================================
  // ENDPOINT PUBLIK (tidak butuh login)
  // ============================================================

  /**
   * Cek reputasi nomor telepon — publik, tidak butuh login.
   * Jika ada token, gunakan sebagai opsional untuk tracking.
   */
  @Get(':number')
  @UseGuards(OptionalJwtAuthGuard)
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

  /**
   * Kirim OTP via WhatsApp — publik (bagian dari alur login)
   */
  @Post('send-otp')
  async sendOtp(
    @Body('phoneNumber') phoneNumber: string,
    @Body('isResend') isResend?: boolean,
  ) {
    return await this.phoneLookupService.sendOtp(phoneNumber, isResend);
  }

  /**
   * Verifikasi OTP dan terbitkan JWT token jika berhasil.
   * Ini adalah "login endpoint" — mengembalikan token yang dipakai untuk request berikutnya.
   */
  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  async verifyOtp(
    @Body('phoneNumber') phoneNumber: string,
    @Body('code') code: string,
  ) {
    const result = await this.phoneLookupService.verifyOtp(phoneNumber, code);
    if (!result.success) {
      return result;
    }
    // OTP valid — terbitkan JWT token
    const token = this.authService.createToken(phoneNumber);
    return {
      ...result,
      token,
      expiresIn: '30d',
    };
  }

  // ============================================================
  // ENDPOINT TERPROTEKSI (wajib login — Bearer JWT)
  // ============================================================

  /**
   * Tambahkan tag ke nomor telepon — wajib login.
   * userId diambil dari token (bukan dari request body) untuk mencegah spoofing.
   */
  @Post('tag')
  @UseGuards(JwtAuthGuard)
  async addTag(
    @Body('phoneNumberId') phoneNumberId: string,
    @Body('labelName') labelName: string,
    @Req() req: AuthenticatedRequest,
  ) {
    // userId diambil dari JWT token yang sudah diverifikasi, bukan dari body
    const userId = req.user?.phoneNumber;
    return await this.phoneLookupService.createTag(phoneNumberId, labelName, userId);
  }

  /**
   * Vote pada tag (upvote/downvote) — wajib login.
   * userId diambil dari token, bukan dari request body.
   */
  @Post('vote')
  @UseGuards(JwtAuthGuard)
  async voteTag(
    @Body('tagId') tagId: string,
    @Body('voteType') voteType: 'UPVOTE' | 'DOWNVOTE',
    @Req() req: AuthenticatedRequest,
  ) {
    // userId diambil dari JWT — mencegah siapapun vote atas nama orang lain
    const userId = req.user!.phoneNumber;
    return await this.phoneLookupService.voteTag(tagId, userId, voteType);
  }

  /**
   * Statistik analitik aplikasi — wajib login.
   */
  @Get('analytics')
  @UseGuards(JwtAuthGuard)
  async getAnalytics() {
    return await this.phoneLookupService.getAnalytics();
  }

  /**
   * Riwayat siapa yang mencari nomor ini — WAJIB LOGIN + OWNERSHIP CHECK.
   * Pengguna hanya boleh melihat riwayat pencari untuk nomor miliknya sendiri.
   */
  @Get('searchers/:number')
  @UseGuards(JwtAuthGuard)
  async getSearchers(
    @Param('number') number: string,
    @Query('limit') limit?: string,
    @Req() req?: AuthenticatedRequest,
  ) {
    // Normalisasi nomor request dan nomor milik user yang login untuk perbandingan
    const normalize = (n: string) =>
      n.trim().replace(/[\s\-().]+/g, '').replace(/^0/, '+62').replace(/^62(?!\+)/, '+62');

    const requestedNumber = normalize(number);
    const ownerNumber = normalize(req?.user?.phoneNumber ?? '');

    // OWNERSHIP CHECK: nomor yang diminta harus sama dengan nomor pengguna yang login
    if (!ownerNumber || requestedNumber !== ownerNumber) {
      throw new ForbiddenException(
        'Akses Ditolak: Anda hanya dapat melihat riwayat pencarian untuk nomor telepon milik Anda sendiri.',
      );
    }

    // Cari ID dari nomor telepon
    const phoneRecord = await this.phoneLookupService['prisma'].phoneNumber.findUnique({
      where: { phoneNumber: requestedNumber },
    });

    if (!phoneRecord) {
      return { success: true, data: [] };
    }

    const maxLimit = limit ? parseInt(limit, 10) : 100;
    const searchers = await this.phoneLookupService.getPhoneSearchers(phoneRecord.id, maxLimit);

    const now = new Date();
    const formattedSearchers = searchers.map((history) => {
      const diffMs = now.getTime() - history.lastSearchedAt.getTime();
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHours / 24);

      let timeStr = 'Baru saja';
      if (diffDays > 0) timeStr = `${diffDays} hari yang lalu`;
      else if (diffHours > 0) timeStr = `${diffHours} jam yang lalu`;
      else if (diffMins > 0) timeStr = `${diffMins} menit yang lalu`;

      return {
        ...history,
        timeAgo: `Memeriksa nomor Anda | ${timeStr}`,
      };
    });

    return { success: true, data: formattedSearchers };
  }

  // ============================================================
  // ENDPOINT ADMIN (wajib admin secret)
  // ============================================================

  /**
   * Reset/hapus data nomor pengguna (right to erasure) — admin only.
   * Membutuhkan header x-admin-secret yang cocok dengan ADMIN_SECRET_KEY di env.
   * Setiap akses (berhasil maupun gagal) dicatat di audit log.
   */
  @Delete('reset/:number')
  async resetNumberData(
    @Param('number') number: string,
    @Headers('x-admin-secret') adminSecret?: string,
    @Ip() callerIp?: string,
  ) {
    // Fail-fast: tolak jika ADMIN_SECRET_KEY tidak dikonfigurasi
    const expectedSecret = process.env.ADMIN_SECRET_KEY;
    if (!expectedSecret) {
      throw new InternalServerErrorException(
        'Konfigurasi server tidak lengkap: ADMIN_SECRET_KEY tidak tersedia di environment variables. Hubungi administrator sistem.',
      );
    }

    if (adminSecret !== expectedSecret) {
      console.warn(
        `[AUDIT][${new Date().toISOString()}] AKSES DITOLAK ke endpoint reset. IP: ${callerIp ?? 'unknown'} | Nomor target: ${number} | Secret dikirim: ${adminSecret ? '[ADA tapi SALAH]' : '[TIDAK ADA]'}`,
      );
      throw new UnauthorizedException(
        'Akses Ditolak: Endpoint ini hanya dapat diakses oleh administrator sistem dengan kunci khusus.',
      );
    }

    console.log(
      `[AUDIT][${new Date().toISOString()}] RESET DIEKSEKUSI. IP: ${callerIp ?? 'unknown'} | Nomor target: ${number}`,
    );

    return await this.phoneLookupService.resetPhoneNumberData(number);
  }

  // ============================================================
  // ENDPOINT NONAKTIF — Sinkronisasi Kontak (Tugas 3)
  // ============================================================

  /**
   * @deprecated Fitur ini dihentikan (HTTP 410 Gone).
   * Gunakan endpoint /report sebagai gantinya.
   * Endpoint ini dipertahankan agar versi app lama tidak crash (bukan 404),
   * tapi tidak lagi memproses data apapun.
   */
  @Post('sync')
  @HttpCode(HttpStatus.GONE)
  async syncContacts(@Body() _dto: SyncContactsDto) {
    return {
      success: false,
      code: 'FEATURE_DISCONTINUED',
      message:
        'Fitur sinkronisasi kontak telah dihentikan sejak versi 2.0. Gunakan endpoint /report untuk melaporkan nomor secara manual.',
    };
  }
}
