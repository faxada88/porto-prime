# Unified Stripe checkout
The same PaymentIntent, total and store-credit deduction are retained. The backend still enables automatic payment methods and only verifies succeeded + exact amount/currency/order/customer before releasing an order.

## App
Native Android/iOS opens a signed, one-hour payment capability in the default browser. Official Stripe Payment Element collects all payment information; Express Checkout displays eligible wallets (Apple Pay, Google Pay, Link). Pix is ordered first; QR and copy/paste plus boleto voucher can be resumed. Background/resume reconciliation checks the same order, never creates another charge.
Web retains inline Elements with responsive height and Pix/boleto action details. The app provides back/home, an item/fee/credit breakdown, an eligibility guide, verification and reopening.

## Activation
Enable methods in the matching test/live Stripe account. Methods are filtered by Stripe for currency, amount, account and device. Wallets require compatible devices/browsers and configured wallets. Production MUST use HTTPS and register the payment page domain in Stripe payment-method domains.
Set API PAYMENTS_PUBLIC_URL to the public HTTPS API origin when behind a proxy, e.g. https://api.portoprimedelivery.com.br. In test mode only, local HTTP localhost/127.0.0.1/10.0.2.2 is accepted. Emulators may not expose wallets even though enabled.
The signed page is served at /api/payments/secure; its capability must not be shared. No authentication token or Stripe secret key is sent to the browser. Capabilities are tied to order+intent, with no-store/referrer restrictions and CSP.
Boleto and generated Pix remain pending; the webhook or authenticated reconciliation confirms them. Keep Stripe CLI forwarding payment_intent.succeeded/payment_intent.payment_failed/payment_intent.canceled during local tests. Generating a boleto is not immediate dispatch.

## Persistence
Additive migration adds BOLETO to the existing method enum. Actual successful Pix maps to PIX, boleto to BOLETO, card/Link/wallet card payments to CARD. No wallet, refund, dispatch, product or pricing logic changes. The updater runs the idempotent SQL directly, so baseline migration history is not rewritten. Standard migrate deploy can later record the same IF NOT EXISTS migration safely.

## Validation
Local checks cover signed-link integrity/expiry, ownership query, preserved intent, unpaid guards, actual method classification, script injection escaping and browser JavaScript syntax. Flutter and full Nest tests/build run on Windows via scripts/update-payment-methods.ps1. Real Stripe test-mode QR/payment, boleto compensation and device wallet acceptance still require end-to-end verification on the configured account/device.
