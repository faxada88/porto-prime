#!/usr/bin/env bash
set -euo pipefail
stripe listen --events payment_intent.succeeded,payment_intent.payment_failed,payment_intent.canceled --forward-to http://localhost:3000/api/payments/webhook
