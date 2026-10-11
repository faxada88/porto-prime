-- Repair partners explicitly activated through the administrative access control.
UPDATE "PartnerProfile" p SET approved=true
FROM "User" u WHERE p."userId"=u.id AND u.role='PARTNER' AND u.status='ACTIVE' AND p.approved=false;
