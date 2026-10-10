-- Preserve the previous manual ON setting only when adding the new mode column.
DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='CourierDemandSignal' AND column_name='mode') THEN
  ALTER TABLE "CourierDemandSignal" ADD COLUMN "mode" TEXT NOT NULL DEFAULT 'AUTO';
  UPDATE "CourierDemandSignal" SET "mode"='MANUAL_ON' WHERE "enabled"=true;
 END IF;
END $$;
ALTER TABLE "CourierDemandSignal" ADD COLUMN IF NOT EXISTS "bonusAmount" DECIMAL(10,2) NOT NULL DEFAULT 2.50;
ALTER TABLE "CourierDemandSignal" ADD COLUMN IF NOT EXISTS "waitingCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "DeliveryOffer" ADD COLUMN IF NOT EXISTS "demandBonus" DECIMAL(10,2) NOT NULL DEFAULT 0;
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "courierDemandBonus" DECIMAL(10,2) NOT NULL DEFAULT 0;
