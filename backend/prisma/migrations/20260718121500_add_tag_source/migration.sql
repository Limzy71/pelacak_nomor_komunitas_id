-- Migration: Add source column to tags table
-- Created: 2026-07-18

ALTER TABLE "tags" ADD COLUMN "source" TEXT NOT NULL DEFAULT 'USER_REPORT';
