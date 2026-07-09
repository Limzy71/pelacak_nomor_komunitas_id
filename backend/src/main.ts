import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // 💡 TAMBAHKAN BARIS INI UNTUK MENGIZINKAN FRONTEND NEXT.JS MENGAKSES API
  app.enableCors({
    origin: 'http://localhost:3001', // Port yang akan kita gunakan untuk Next.js nanti
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  await app.listen(3000);
  console.log('Backend Phone Reputation Check API berjalan di http://localhost:3000');
}
bootstrap();
