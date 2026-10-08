-- Additive financial tables. Courier balances and historical ledger are unchanged.
CREATE TABLE IF NOT EXISTS "PartnerLedgerEntry" (
 "id" TEXT PRIMARY KEY, "userId" TEXT NOT NULL REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
 "type" "WalletEntryType" NOT NULL, "amount" DECIMAL(10,2) NOT NULL, "description" TEXT NOT NULL,
 "idempotencyKey" TEXT NOT NULL UNIQUE, "availableAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 "metadata" JSONB, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "PartnerLedgerEntry_userId_availableAt_idx" ON "PartnerLedgerEntry"("userId","availableAt");
CREATE TABLE IF NOT EXISTS "PartnerWithdrawal" (
 "id" TEXT PRIMARY KEY, "userId" TEXT NOT NULL REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
 "amount" DECIMAL(10,2) NOT NULL, "status" "WithdrawalStatus" NOT NULL DEFAULT 'PENDING',
 "pixKeyType" "PixKeyType" NOT NULL, "pixKey" TEXT NOT NULL, "receiptUrl" TEXT,
 "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "processedAt" TIMESTAMP(3),
 "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL
);
CREATE INDEX IF NOT EXISTS "PartnerWithdrawal_userId_idx" ON "PartnerWithdrawal"("userId");
CREATE INDEX IF NOT EXISTS "PartnerWithdrawal_status_idx" ON "PartnerWithdrawal"("status");
CREATE TABLE IF NOT EXISTS "FinancialAudit" (
 "id" TEXT PRIMARY KEY, "actorId" TEXT NOT NULL, "actorName" TEXT NOT NULL, "accountUserId" TEXT NOT NULL,
 "action" TEXT NOT NULL, "amount" DECIMAL(10,2) NOT NULL, "reason" TEXT NOT NULL,
 "reference" TEXT, "withdrawalId" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "FinancialAudit_accountUserId_createdAt_idx" ON "FinancialAudit"("accountUserId","createdAt");
CREATE INDEX IF NOT EXISTS "FinancialAudit_withdrawalId_idx" ON "FinancialAudit"("withdrawalId");
