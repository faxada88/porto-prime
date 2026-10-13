ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "paidAt" TIMESTAMP(3);
UPDATE "Order" SET "paidAt"="createdAt" WHERE "paidAt" IS NULL AND "paymentStatus" IN ('PAID','PARTIALLY_REFUNDED','REFUNDED');
CREATE TABLE IF NOT EXISTS "OrderCancellation" (
 "id" TEXT NOT NULL, "orderId" TEXT NOT NULL, "customerId" TEXT NOT NULL, "courierId" TEXT,
 "fee" DECIMAL(10,2) NOT NULL, "cashRefund" DECIMAL(10,2) NOT NULL, "creditRefund" DECIMAL(10,2) NOT NULL,
 "paymentIntentId" TEXT, "reason" TEXT NOT NULL, "status" TEXT NOT NULL DEFAULT 'PENDING',
 "stripeRefundId" TEXT, "stripeRefundStatus" TEXT, "refundAttempt" INTEGER NOT NULL DEFAULT 0,
 "refundHistory" JSONB NOT NULL DEFAULT '[]', "lastError" TEXT,
 "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "completedAt" TIMESTAMP(3),
 CONSTRAINT "OrderCancellation_pkey" PRIMARY KEY ("id"),
 CONSTRAINT "OrderCancellation_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS "OrderCancellation_orderId_key" ON "OrderCancellation"("orderId");
CREATE INDEX IF NOT EXISTS "OrderCancellation_status_createdAt_idx" ON "OrderCancellation"("status","createdAt");
