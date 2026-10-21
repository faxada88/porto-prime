-- Additive classification only; no order/wallet data is changed.
ALTER TYPE "PaymentMethod" ADD VALUE IF NOT EXISTS 'BOLETO';
