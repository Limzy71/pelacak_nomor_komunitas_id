# 🛡️ PhoneRep ID — Crowdsourced Caller-ID & Contact Pooling System

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![NestJS](https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white)
![Prisma](https://img.shields.io/badge/Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)

**PhoneRep ID** adalah platform *Full-Stack Monorepo* yang merangkum aplikasi mobile native Android dan backend server modern untuk mengidentifikasi nomor telepon asing, menganalisis indeks kepercayaan (*Trust Score*) anti-spam, serta mengelola sinkronisasi kontak massal (*Contact Pooling*) secara *real-time* berbasis komunitas (*crowdsourcing*).

---

## 🏗️ Arsitektur Monorepo

Repository ini dibagi menjadi dua modul utama:

- **`📁 /backend`** — RESTful API Server yang dibangun menggunakan **NestJS**, **Prisma ORM**, dan **PostgreSQL**. Menangani logika sinkronisasi kontak massal, kalkulasi *Trust Score*, deteksi operator dinamis, serta manajemen *upvote/downvote* label.
- **`📁 /mobile`** — Aplikasi Mobile Native Android yang dibangun menggunakan **Flutter & Dart**. Dilengkapi dengan fitur perizinan akses kontak lokal, sinkronisasi otomatis ke server, dan antarmuka pencarian nomor bertemakan *Modern Dark Mode*.

---

## ✨ Fitur Utama

1. **📲 Real-Time Contact Pooling (`POST /phone-lookup/sync`)**
   - Mengakses buku kontak di perangkat Android secara lokal dengan izin pengguna (`READ_CONTACTS`).
   - Menyinkronkan ratusan kontak secara otomatis dan massal ke database PostgreSQL dengan normalisasi nomor internasional (**E.164**).
   - Mencegah duplikasi data dan secara otomatis mengkalkulasi reputasi label (*Auto-Upvote*) berdasarkan jumlah kontribusi lintas pengguna.

2. **🔍 Instant Phone Number Lookup & Carrier Detection**
   - Pencarian nomor telepon super cepat dengan pemuatan relasi (*Eager Loading*) untuk menampilkan seluruh daftar label dari komunitas.
   - **Dynamic Carrier Detection**: Parsing kode negara dan deteksi operator seluler Indonesia (Telkomsel, Indosat, XL Axiata, Smartfren, dll) secara otomatis tanpa ketergantungan API pihak ketiga yang rawan diblokir.

3. **🏷️ Crowdsourced Tagging & Anti-Double Voting System**
   - Pengguna dapat menyumbangkan label/tag baru secara langsung pada nomor yang dicari.
   - Sistem *voting* interaktif (`UPVOTE` & `DOWNVOTE`) yang dilindungi oleh *database unique constraint* (`@@unique([tagId, userId])`) untuk mencegah manipulasi skor ganda.
