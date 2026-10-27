-- Porto Prime: daily 4-digit order number (0001-9999).
-- The existing opaque Order.id and deliveryPin remain untouched.
-- Numbers are stable, unique on their Porto Seguro calendar day, and may
-- naturally be reused on another date, as is usual for printed kitchen tickets.
ALTER TABLE "Order"
  ADD COLUMN "displayNumber" INTEGER,
  ADD COLUMN "displayDay" VARCHAR(10);

CREATE TABLE "DailyOrderNumber" (
  "day" VARCHAR(10) NOT NULL,
  "currentNumber" INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT "DailyOrderNumber_pkey" PRIMARY KEY ("day")
);

-- Give existing orders stable numbers in creation order on their local day.
-- On a deployment with over 9999 orders on one day, fail safely rather than
-- produce ambiguous four-digit receipts.
DO $$
BEGIN
 IF EXISTS (
   SELECT 1 FROM (
     SELECT COUNT(*) AS count FROM "Order"
     GROUP BY to_char(("createdAt" AT TIME ZONE 'UTC') AT TIME ZONE 'America/Bahia', 'YYYY-MM-DD')
   ) AS daily WHERE daily.count > 9999
 ) THEN
  RAISE EXCEPTION 'Há mais de 9999 pedidos em um dia; não é possível atribuir comprovantes únicos com quatro dígitos';
 END IF;
END $$;

WITH numbered AS (
 SELECT "id",
        to_char(("createdAt" AT TIME ZONE 'UTC') AT TIME ZONE 'America/Bahia','YYYY-MM-DD') AS day,
        ROW_NUMBER() OVER (
          PARTITION BY to_char(("createdAt" AT TIME ZONE 'UTC') AT TIME ZONE 'America/Bahia','YYYY-MM-DD')
          ORDER BY "createdAt","id"
        ) AS n
 FROM "Order"
)
UPDATE "Order" AS o
SET "displayDay" = n.day, "displayNumber" = n.n
FROM numbered AS n WHERE o."id" = n."id";

INSERT INTO "DailyOrderNumber" ("day","currentNumber")
 SELECT "displayDay",MAX("displayNumber")
 FROM "Order" WHERE "displayDay" IS NOT NULL GROUP BY "displayDay"
 ON CONFLICT ("day") DO UPDATE
 SET "currentNumber" = GREATEST("DailyOrderNumber"."currentNumber", EXCLUDED."currentNumber");

CREATE UNIQUE INDEX "Order_displayDay_displayNumber_key"
 ON "Order"("displayDay","displayNumber");
ALTER TABLE "Order"
 ADD CONSTRAINT "Order_displayNumber_four_digits_chk"
 CHECK ("displayNumber" IS NULL OR "displayNumber" BETWEEN 1 AND 9999);
