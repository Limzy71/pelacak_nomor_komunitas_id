import { Injectable, ExecutionContext } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Reflector } from '@nestjs/core';

/**
 * Guard JWT standar — wajib login (ada Bearer token yang valid).
 * Dipakai di endpoint yang butuh autentikasi penuh.
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    return super.canActivate(context);
  }
}

/**
 * Guard JWT opsional — jika tidak ada token, req.user = undefined (tidak throw error).
 * Dipakai di endpoint publik yang bisa dipakai lebih kaya fitur jika login.
 */
@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  // Inject Reflector agar kompiler TypeScript tidak complain
  constructor(private reflector?: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext) {
    // Selalu return true, tapi tetap coba proses token jika ada
    return super.canActivate(context);
  }

  // Override handleRequest — jika token tidak ada/invalid, kembalikan undefined (bukan throw)
  handleRequest(_err: any, user: any) {
    return user ?? undefined;
  }
}
