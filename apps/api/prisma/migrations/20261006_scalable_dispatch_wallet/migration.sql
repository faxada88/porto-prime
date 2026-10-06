-- Arquitetura escalável: sessões multidispositivo, presença, despacho,
-- auditoria, wallet/ledger e precificação.

DO $$ BEGIN
  CREATE TYPE "CourierPresenceStatus" AS ENUM ('OFFLINE','AVAILABLE','OFFERED','DELIVERING','UNAVAILABLE');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "DeliveryOfferStatus" AS ENUM ('PENDING','ACCEPTED','DECLINED','EXPIRED','CANCELED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "WalletEntryType" AS ENUM ('DELIVERY_CREDIT','WITHDRAWAL_DEBIT','BONUS_CREDIT','ADJUSTMENT_CREDIT','ADJUSTMENT_DEBIT','REVERSAL');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "DispatchEventType" AS ENUM ('ADMIN_RELEASED','SEARCH_STARTED','OFFER_CREATED','OFFER_DECLINED','OFFER_EXPIRED','OFFER_CANCELED','OFFER_ACCEPTED','COURIER_PICKED_UP','OUT_FOR_DELIVERY','DELIVERED','WALLET_CREDITED','WITHDRAWAL_REQUESTED','WITHDRAWAL_STATUS_CHANGED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TYPE "OrderStatus" ADD VALUE IF NOT EXISTS 'SEARCHING_COURIER';

ALTER TABLE "CourierProfile"
  ADD COLUMN IF NOT EXISTS "presenceStatus" "CourierPresenceStatus" NOT NULL DEFAULT 'OFFLINE',
  ADD COLUMN IF NOT EXISTS "lastHeartbeatAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "availableSince" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "lastOfferAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "currentLatitude" DECIMAL(10,7),
  ADD COLUMN IF NOT EXISTS "currentLongitude" DECIMAL(10,7),
  ADD COLUMN IF NOT EXISTS "locationUpdatedAt" TIMESTAMP(3);

ALTER TABLE "Order"
  ADD COLUMN IF NOT EXISTS "routeDistanceKm" DECIMAL(10,3),
  ADD COLUMN IF NOT EXISTS "routeDurationMinutes" INTEGER;

ALTER TABLE "AuthSession"
  ADD COLUMN IF NOT EXISTS "refreshTokenHash" TEXT,
  ADD COLUMN IF NOT EXISTS "deviceId" TEXT,
  ADD COLUMN IF NOT EXISTS "deviceName" TEXT,
  ADD COLUMN IF NOT EXISTS "userAgent" TEXT,
  ADD COLUMN IF NOT EXISTS "ipAddress" TEXT,
  ADD COLUMN IF NOT EXISTS "refreshExpiresAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS "revokedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "revokedReason" TEXT,
  ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE UNIQUE INDEX IF NOT EXISTS "AuthSession_refreshTokenHash_key" ON "AuthSession"("refreshTokenHash");
CREATE INDEX IF NOT EXISTS "AuthSession_userId_revokedAt_idx" ON "AuthSession"("userId","revokedAt");
CREATE INDEX IF NOT EXISTS "AuthSession_refreshExpiresAt_idx" ON "AuthSession"("refreshExpiresAt");

ALTER TABLE "CourierLedgerEntry"
  ADD COLUMN IF NOT EXISTS "type" "WalletEntryType",
  ADD COLUMN IF NOT EXISTS "idempotencyKey" TEXT,
  ADD COLUMN IF NOT EXISTS "availableAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS "metadata" JSONB;

UPDATE "CourierLedgerEntry"
SET "type" = 'DELIVERY_CREDIT'
WHERE "type" IS NULL;

UPDATE "CourierLedgerEntry"
SET "idempotencyKey" = 'legacy:' || "id"
WHERE "idempotencyKey" IS NULL;

ALTER TABLE "CourierLedgerEntry"
  ALTER COLUMN "type" SET NOT NULL,
  ALTER COLUMN "idempotencyKey" SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "CourierLedgerEntry_idempotencyKey_key" ON "CourierLedgerEntry"("idempotencyKey");
CREATE INDEX IF NOT EXISTS "CourierLedgerEntry_courierId_availableAt_idx" ON "CourierLedgerEntry"("courierId","availableAt");

CREATE TABLE IF NOT EXISTS "DeliveryOffer" (
  "id" TEXT NOT NULL,
  "orderId" TEXT NOT NULL,
  "courierId" TEXT NOT NULL,
  "status" "DeliveryOfferStatus" NOT NULL DEFAULT 'PENDING',
  "score" DECIMAL(12,4),
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "offeredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "respondedAt" TIMESTAMP(3),
  "acceptedAt" TIMESTAMP(3),
  "declinedAt" TIMESTAMP(3),
  "expiredAt" TIMESTAMP(3),
  "canceledAt" TIMESTAMP(3),
  "distanceToPickupKm" DECIMAL(10,3),
  "metadata" JSONB,
  CONSTRAINT "DeliveryOffer_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "DeliveryOffer_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "DeliveryOffer_courierId_fkey" FOREIGN KEY ("courierId") REFERENCES "CourierProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "DeliveryOffer_orderId_status_idx" ON "DeliveryOffer"("orderId","status");
CREATE INDEX IF NOT EXISTS "DeliveryOffer_courierId_status_idx" ON "DeliveryOffer"("courierId","status");
CREATE INDEX IF NOT EXISTS "DeliveryOffer_expiresAt_status_idx" ON "DeliveryOffer"("expiresAt","status");

CREATE TABLE IF NOT EXISTS "DispatchEvent" (
  "id" TEXT NOT NULL,
  "orderId" TEXT NOT NULL,
  "courierId" TEXT,
  "offerId" TEXT,
  "type" "DispatchEventType" NOT NULL,
  "payload" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "DispatchEvent_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "DispatchEvent_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "DispatchEvent_orderId_createdAt_idx" ON "DispatchEvent"("orderId","createdAt");
CREATE INDEX IF NOT EXISTS "DispatchEvent_courierId_createdAt_idx" ON "DispatchEvent"("courierId","createdAt");

CREATE TABLE IF NOT EXISTS "DeliveryPricingConfig" (
  "id" TEXT NOT NULL DEFAULT 'default',
  "distributorName" TEXT NOT NULL DEFAULT 'Porto Prime Delivery',
  "distributorAddress" TEXT,
  "distributorLatitude" DECIMAL(10,7),
  "distributorLongitude" DECIMAL(10,7),
  "baseFee" DECIMAL(10,2) NOT NULL DEFAULT 5.90,
  "includedKm" DECIMAL(10,2) NOT NULL DEFAULT 3.00,
  "pricePerAdditionalKm" DECIMAL(10,2) NOT NULL DEFAULT 2.00,
  "maxDistanceKm" DECIMAL(10,2) NOT NULL DEFAULT 25.00,
  "minDeliveryFee" DECIMAL(10,2) NOT NULL DEFAULT 5.90,
  "maxDeliveryFee" DECIMAL(10,2) NOT NULL DEFAULT 80.00,
  "offerTimeoutSeconds" INTEGER NOT NULL DEFAULT 30,
  "heartbeatTimeoutSeconds" INTEGER NOT NULL DEFAULT 45,
  "platformCommissionPercent" DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  "regionRules" JSONB,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "DeliveryPricingConfig_pkey" PRIMARY KEY ("id")
);

INSERT INTO "DeliveryPricingConfig" ("id")
VALUES ('default')
ON CONFLICT ("id") DO NOTHING;

ALTER TABLE "Order"
  ADD COLUMN IF NOT EXISTS "activeOfferId" TEXT;

CREATE INDEX IF NOT EXISTS "Order_activeOfferId_idx" ON "Order"("activeOfferId");
