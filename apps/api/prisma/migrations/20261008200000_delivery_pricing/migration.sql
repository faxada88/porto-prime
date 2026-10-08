ALTER TABLE "Address" ADD COLUMN IF NOT EXISTS "locationConfirmed" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "DeliveryPricingConfig" ADD COLUMN IF NOT EXISTS "pricingRevision" INTEGER NOT NULL DEFAULT 0;
UPDATE "DeliveryPricingConfig" SET "baseFee"=5.50, "includedKm"=3, "pricePerAdditionalKm"=2.50, "minDeliveryFee"=5.50, "platformCommissionPercent"=0, "pricingRevision"=1 WHERE "pricingRevision"=0;
ALTER TABLE "DeliveryPricingConfig" ALTER COLUMN "pricingRevision" SET DEFAULT 1;
ALTER TABLE "DeliveryPricingConfig" ALTER COLUMN "baseFee" SET DEFAULT 5.50;
ALTER TABLE "DeliveryPricingConfig" ALTER COLUMN "minDeliveryFee" SET DEFAULT 5.50;
ALTER TABLE "DeliveryPricingConfig" ALTER COLUMN "pricePerAdditionalKm" SET DEFAULT 2.50;
