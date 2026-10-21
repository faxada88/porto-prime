# Unified Stripe checkout
The same PaymentIntent, total and store-credit deduction are retained. The backend still enables automatic payment methods and only verifies succeeded + exact amount/currency/order/customer before releasing an order.

## App
Native Android/iOS now remains inside the app. A Flutter selector offers eligible Pix, card, wallets and boleto. Card/Link/wallet/boleto fields use official native Stripe PaymentSheet with delayed methods enabled. Google Pay is optional and uses the matching test/live environment. Apple Pay is configured only when STRIPE_APPLE_MERCHANT_ID is provided as a Flutter dart-define and the Apple merchant/entitlement setup exists.
Pix uses an authenticated endpoint to confirm the existing PaymentIntent and displays Stripe's QR + copy/paste in a native modal. Active QR codes are recovered without another confirmation. Polling/resume uses server reconciliation. No external browser or Google sign-in is opened automatically by the native checkout.
Web retains inline Elements with responsive height and Pix/boleto action details. The app provides back/home, an item/fee/credit breakdown, an eligibility guide, verification and reopening.

## Activation
Enable methods in the matching test/live Stripe account. Methods are filtered by Stripe for currency, amount, account and device. Wallets require compatible devices/browsers and configured wallets. Production MUST use HTTPS and register the payment page domain in Stripe payment-method domains.
Set API PAYMENTS_PUBLIC_URL to the public HTTPS API origin when behind a proxy, e.g. https://api.portoprimedelivery.com.br. In test mode only, local HTTP localhost/127.0.0.1/10.0.2.2 is accepted. Emulators may not expose wallets even though enabled.
The legacy signed web page remains available for web integrations, but is never opened by the Android/iOS checkout. It is served at /api/payments/secure; its capability must not be shared. No authentication token or Stripe secret key is sent to the browser. Capabilities are tied to order+intent, with no-store/referrer restrictions and CSP.
Boleto and generated Pix remain pending; the webhook or authenticated reconciliation confirms them. Keep Stripe CLI forwarding payment_intent.succeeded/payment_intent.payment_failed/payment_intent.canceled during local tests. Generating a boleto is not immediate dispatch.

## Persistence
Additive migration adds BOLETO to the existing method enum. Actual successful Pix maps to PIX, boleto to BOLETO, card/Link/wallet card payments to CARD. No wallet, refund, dispatch, product or pricing logic changes. The updater runs the idempotent SQL directly, so baseline migration history is not rewritten. Standard migrate deploy can later record the same IF NOT EXISTS migration safely.

## Validation
Local checks cover signed-link integrity/expiry, ownership query, preserved intent, unpaid guards, actual method classification, script injection escaping and browser JavaScript syntax. Flutter and full Nest tests/build run on Windows via scripts/update-payment-methods.ps1. Real Stripe test-mode QR/payment, boleto compensation and device wallet acceptance still require end-to-end verification on the configured account/device.

## Native correction validation
Tests exercise in-app method selection, text scaling, Pix copying, server-only confirmation, existing QR reuse, idempotent confirmation, ownership and unpaid guards. There is no launchUrl/externalApplication/secure-checkout navigation in the native checkout. Selecting a wallet can require that wallet's own authentication; card and Pix do not require a Google account.


## Simplified checkout, boleto removed
The payment review now contains one total, a collapsible item/fee/credit summary, the saved delivery address and an on-page picker with Pix or Card/wallets. Its single bottom action opens the chosen modal directly; there is no extra selection sheet or decorative payment-method chips.
New intents exclude boleto server-side. Existing intents still awaiting a payment method are updated to exclude boleto before reuse, including native-options and the fallback web page. Existing issued/processing/paid boleto payments are preserved for reconciliation and financial history, never canceled as a UI side effect.
Native PaymentSheet disallows delayed payment methods and only orders card/link. Pix keeps its native QR/copy modal. Success is still verified server-side before any order release.
