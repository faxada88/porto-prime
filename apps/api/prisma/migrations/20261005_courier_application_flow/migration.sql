CREATE TYPE "RequirementStatus" AS ENUM ('OPEN','ANSWERED','RESOLVED');
ALTER TABLE "CourierProfile" ADD COLUMN "cnh" TEXT, ADD COLUMN "cnhCategory" TEXT, ADD COLUMN "vehicleBrand" TEXT, ADD COLUMN "vehicleModel" TEXT, ADD COLUMN "vehiclePlate" TEXT, ADD COLUMN "vehicleYear" INTEGER;
CREATE UNIQUE INDEX "CourierProfile_document_key" ON "CourierProfile"("document");
CREATE TABLE "CourierRequirement" (
 "id" TEXT NOT NULL, "courierId" TEXT NOT NULL, "title" TEXT NOT NULL, "description" TEXT NOT NULL,
 "response" TEXT, "status" "RequirementStatus" NOT NULL DEFAULT 'OPEN', "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 "answeredAt" TIMESTAMP(3), "resolvedAt" TIMESTAMP(3), CONSTRAINT "CourierRequirement_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "CourierRequirement_courierId_status_idx" ON "CourierRequirement"("courierId","status");
ALTER TABLE "CourierRequirement" ADD CONSTRAINT "CourierRequirement_courierId_fkey" FOREIGN KEY ("courierId") REFERENCES "CourierProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;