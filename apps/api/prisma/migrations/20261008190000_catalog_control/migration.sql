-- Non-destructive, repeatable update. Historical order items remain intact.
ALTER TABLE "Product" ADD COLUMN IF NOT EXISTS "archived" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "Category" ADD COLUMN IF NOT EXISTS "archived" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "DeliveryPricingConfig" ADD COLUMN IF NOT EXISTS "storeOpen" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "DeliveryPricingConfig" ADD COLUMN IF NOT EXISTS "storeMessage" TEXT NOT NULL DEFAULT 'Voltaremos em breve. Sua sacola continua salva.';
