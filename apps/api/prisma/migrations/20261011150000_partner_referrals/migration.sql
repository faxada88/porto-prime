ALTER TABLE "PartnerProfile" ADD COLUMN IF NOT EXISTS "referralCode" TEXT;
UPDATE "PartnerProfile" SET "referralCode"='PP-'||UPPER(SUBSTRING(MD5(id) FROM 1 FOR 16)) WHERE "referralCode" IS NULL;
ALTER TABLE "PartnerProfile" ALTER COLUMN "referralCode" SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "PartnerProfile_referralCode_key" ON "PartnerProfile"("referralCode");
ALTER TABLE "PartnerProfile" ADD COLUMN IF NOT EXISTS "commissionPercent" DECIMAL(5,2) NOT NULL DEFAULT 5;
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "referralPartnerId" TEXT;
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "partnerCommissionPercent" DECIMAL(5,2) NOT NULL DEFAULT 0;
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "partnerCommissionAmount" DECIMAL(10,2) NOT NULL DEFAULT 0;
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "partnerCommissionCreditedAt" TIMESTAMP(3);
CREATE INDEX IF NOT EXISTS "Order_referralPartnerId_createdAt_idx" ON "Order"("referralPartnerId","createdAt");
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='Order_referralPartnerId_fkey') THEN
 ALTER TABLE "Order" ADD CONSTRAINT "Order_referralPartnerId_fkey" FOREIGN KEY ("referralPartnerId") REFERENCES "PartnerProfile"(id) ON DELETE RESTRICT ON UPDATE CASCADE;
END IF; END $$;
