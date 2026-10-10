-- Old orders keep the distributor-funded promise; no retroactive charge.
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "demandSurchargeIncluded" BOOLEAN NOT NULL DEFAULT false;
