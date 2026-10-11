CREATE TABLE IF NOT EXISTS "DeliveryChatMessage" (
 "id" TEXT NOT NULL, "orderId" TEXT NOT NULL, "senderId" TEXT NOT NULL,
 "senderRole" "UserRole" NOT NULL, "text" TEXT NOT NULL, "requestId" TEXT NOT NULL,
 "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "DeliveryChatMessage_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "DeliveryChatMessage_senderId_requestId_key" ON "DeliveryChatMessage"("senderId","requestId");
CREATE INDEX IF NOT EXISTS "DeliveryChatMessage_orderId_createdAt_id_idx" ON "DeliveryChatMessage"("orderId","createdAt","id");
