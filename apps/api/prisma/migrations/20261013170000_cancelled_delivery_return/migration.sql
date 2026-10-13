ALTER TABLE "OrderCancellation" ADD COLUMN IF NOT EXISTS "returnStatus" TEXT NOT NULL DEFAULT 'NOT_REQUIRED';
ALTER TABLE "OrderCancellation" ADD COLUMN IF NOT EXISTS "returnStartedAt" TIMESTAMP(3);
ALTER TABLE "OrderCancellation" ADD COLUMN IF NOT EXISTS "returnArrivedAt" TIMESTAMP(3);
ALTER TABLE "OrderCancellation" ADD COLUMN IF NOT EXISTS "returnedAt" TIMESTAMP(3);
ALTER TABLE "OrderCancellation" ADD COLUMN IF NOT EXISTS "returnConfirmedBy" TEXT;
CREATE INDEX IF NOT EXISTS "OrderCancellation_courierId_returnStatus_idx" ON "OrderCancellation"("courierId","returnStatus");
