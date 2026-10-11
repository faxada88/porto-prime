-- Additive, repeatable installation; no operational or financial tables are changed.
BEGIN;
CREATE TABLE IF NOT EXISTS "SupportThread" (
 "id" TEXT PRIMARY KEY, "ownerId" TEXT REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE,
 "ownerRole" "UserRole" NOT NULL, "orderId" TEXT, "category" TEXT NOT NULL, "subject" TEXT NOT NULL,
 "status" TEXT NOT NULL DEFAULT 'OPEN', "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "SupportThread_status_check" CHECK ("status" IN ('OPEN','IN_PROGRESS','RESOLVED'))
);
CREATE UNIQUE INDEX IF NOT EXISTS "SupportThread_ownerId_orderId_key" ON "SupportThread"("ownerId","orderId");
CREATE INDEX IF NOT EXISTS "SupportThread_status_updatedAt_idx" ON "SupportThread"("status","updatedAt");
CREATE INDEX IF NOT EXISTS "SupportThread_ownerId_updatedAt_idx" ON "SupportThread"("ownerId","updatedAt");
CREATE TABLE IF NOT EXISTS "SupportMessage" (
 "id" TEXT PRIMARY KEY, "threadId" TEXT NOT NULL REFERENCES "SupportThread"("id") ON DELETE CASCADE ON UPDATE CASCADE,
 "senderId" TEXT REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE,
 "senderRole" "UserRole" NOT NULL, "text" TEXT NOT NULL, "requestId" TEXT NOT NULL,
 "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS "SupportMessage_senderId_requestId_key" ON "SupportMessage"("senderId","requestId");
CREATE INDEX IF NOT EXISTS "SupportMessage_threadId_createdAt_id_idx" ON "SupportMessage"("threadId","createdAt","id");
COMMIT;
