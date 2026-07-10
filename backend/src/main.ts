import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // 💡 Mengizinkan semua origin (Web/Mobile App di jaringan Wi-Fi lokal) mengakses API
  app.enableCors({
    origin: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  // 💡 Bind ke '0.0.0.0' agar bisa diakses dari perangkat HP (IP Lokal seperti 192.168.x.x)
  await app.listen(3000, '0.0.0.0');
  console.log('Backend Phone Reputation Check API berjalan di http://0.0.0.0:3000');
}
bootstrap();
