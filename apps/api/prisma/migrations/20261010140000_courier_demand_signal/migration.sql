CREATE TABLE IF NOT EXISTS "CourierDemandSignal" (
 "id" TEXT NOT NULL DEFAULT 'default',
 "enabled" BOOLEAN NOT NULL DEFAULT false,
 "revision" INTEGER NOT NULL DEFAULT 0,
 "updatedBy" TEXT,
 "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT "CourierDemandSignal_pkey" PRIMARY KEY ("id")
);
