-- Migration: Change trust_score default value from 100.0 to 50.0
-- Created: 2026-07-18
-- Note: ALTER COLUMN DEFAULT hanya mempengaruhi baris BARU yang dibuat setelah migrasi ini.
--       Baris existing di database TIDAK berubah nilainya (sesuai requirement Tugas 4).

ALTER TABLE "phone_numbers" ALTER COLUMN "trust_score" SET DEFAULT 50.0;
