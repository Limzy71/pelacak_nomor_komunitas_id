import { PrismaClient } from '../generated/prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import 'dotenv/config';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is not defined in environment variables');
}

const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('Menghapus data lama (jika ada)...');
  await prisma.tagVote.deleteMany();
  await prisma.tag.deleteMany();
  await prisma.phoneNumber.deleteMany();
  await prisma.user.deleteMany();

  console.log('Memperbarui akun admin default...');
  await prisma.user.create({
    data: {
      email: 'admin@phonerep.check',
      name: 'Admin PhoneRep',
      password: '$2b$10$YourHashedPasswordHere', // Hash bcrypt placeholder
    },
  });

  console.log('Membuat akun simulated user untuk frontend testing...');
  await prisma.user.create({
    data: {
      id: 'simulated-user-id-123',
      email: 'tester@phonerep.check',
      name: 'Simulated Tester',
      password: '$2b$10$YourHashedPasswordHere',
    },
  });

  console.log('Database berhasil dibersihkan dari seluruh data dummy nomor telepon! 🌱');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });