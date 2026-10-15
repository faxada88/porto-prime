CREATE TABLE IF NOT EXISTS "PublicContact" (
 "id" TEXT NOT NULL PRIMARY KEY,"protocol" TEXT NOT NULL,"requestId" TEXT NOT NULL,"keyHash" TEXT NOT NULL,"requestHash" TEXT NOT NULL,
 "name" TEXT NOT NULL,"email" TEXT NOT NULL,"phone" TEXT NOT NULL,"company" TEXT NOT NULL,"persona" TEXT NOT NULL,"topic" TEXT NOT NULL,
 "status" TEXT NOT NULL DEFAULT 'OPEN',"notes" TEXT,"createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,"updatedAt" TIMESTAMP(3) NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "PublicContact_protocol_key" ON "PublicContact"("protocol");
CREATE UNIQUE INDEX IF NOT EXISTS "PublicContact_requestId_key" ON "PublicContact"("requestId");
CREATE INDEX IF NOT EXISTS "PublicContact_status_updatedAt_idx" ON "PublicContact"("status","updatedAt");
CREATE INDEX IF NOT EXISTS "PublicContact_topic_updatedAt_idx" ON "PublicContact"("topic","updatedAt");
CREATE INDEX IF NOT EXISTS "PublicContact_email_createdAt_idx" ON "PublicContact"("email","createdAt");
CREATE TABLE IF NOT EXISTS "PublicContactMessage" (
 "id" TEXT NOT NULL PRIMARY KEY,"contactId" TEXT NOT NULL,"senderRole" TEXT NOT NULL,"senderId" TEXT,"requestId" TEXT NOT NULL,"text" TEXT NOT NULL,
 "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "PublicContactMessage_contactId_fkey" FOREIGN KEY ("contactId") REFERENCES "PublicContact"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS "PublicContactMessage_contactId_senderRole_requestId_key" ON "PublicContactMessage"("contactId","senderRole","requestId");
CREATE INDEX IF NOT EXISTS "PublicContactMessage_contactId_createdAt_id_idx" ON "PublicContactMessage"("contactId","createdAt","id");
