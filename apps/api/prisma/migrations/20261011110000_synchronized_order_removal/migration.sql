BEGIN;
-- Stop offers and dispatch left running by previous admin-only hiding.
UPDATE "DeliveryOffer" AS offer SET "status"='CANCELED', "respondedAt"=NOW(), "canceledAt"=NOW()
FROM "Order" AS orders WHERE offer."orderId"=orders.id AND orders."adminDeletedAt" IS NOT NULL AND offer.status='PENDING';
UPDATE "Order" SET "activeOfferId"=NULL, status='CANCELED', "canceledAt"=COALESCE("canceledAt",NOW()), "updatedAt"=NOW()
WHERE "adminDeletedAt" IS NOT NULL AND status NOT IN ('DELIVERED','CANCELED');
UPDATE "Order" SET "activeOfferId"=NULL WHERE "adminDeletedAt" IS NOT NULL AND "activeOfferId" IS NOT NULL;
UPDATE "CourierProfile" AS courier SET "presenceStatus"=CASE WHEN courier."isOnline" THEN 'AVAILABLE'::"CourierPresenceStatus" ELSE 'OFFLINE'::"CourierPresenceStatus" END,
"availableSince"=CASE WHEN courier."isOnline" THEN NOW() ELSE NULL END
WHERE courier."presenceStatus" IN ('OFFERED','DELIVERING')
AND (EXISTS(SELECT 1 FROM "Order" orders WHERE orders."courierId"=courier.id AND orders."adminDeletedAt" IS NOT NULL)
OR EXISTS(SELECT 1 FROM "DeliveryOffer" offer JOIN "Order" orders ON orders.id=offer."orderId" WHERE offer."courierId"=courier.id AND orders."adminDeletedAt" IS NOT NULL))
AND NOT EXISTS(SELECT 1 FROM "Order" orders WHERE orders."courierId"=courier.id AND orders."adminDeletedAt" IS NULL AND orders.status NOT IN ('DELIVERED','CANCELED'))
AND NOT EXISTS(SELECT 1 FROM "DeliveryOffer" offer JOIN "Order" orders ON orders.id=offer."orderId" WHERE offer."courierId"=courier.id AND offer.status='PENDING' AND offer."expiresAt">NOW() AND orders."adminDeletedAt" IS NULL);
COMMIT;
