-- Registration identity integrity.
-- Existing duplicate/non-normalized production data must be reconciled before applying this migration.
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "document" TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS "User_document_key" ON "User"("document");
