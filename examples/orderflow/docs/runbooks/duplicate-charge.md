# Duplicate Charge — Runbook

**Scenario:** A redelivered charge request does not double-charge.

## What this proves

[`../../services/payments/DESIGN.md`](../../services/payments/DESIGN.md) Rules &
Invariants #1 — one charge per order: the same order can occupy at most one row in the
`charges` table, ever, even if the charge queue delivers the same `charge-requested`
message twice.

## Environment preconditions

- The charge queue and settled queue are running locally.
- The database is up and has the `charges` table, empty for the test order's `orderId`.
- The payment provider is a fake that records every call it receives; no real provider
  is used.

## Steps

1. Place an order through the orders API (`POST /orders`), or publish a crafted
   `charge-requested` message directly onto the charge queue for a test `orderId`.
2. Let the payments service consume the message and settle the charge.
3. Deliver the exact same `charge-requested` message a second time, with the same
   `orderId`.
4. Inspect the `charges` table for rows with that `orderId`.
5. Inspect the fake provider's call log for calls carrying that `orderId`.
6. Inspect the settled queue for `charge-settled` messages carrying that `orderId`.

## Pass criteria

- Exactly one row exists in `charges` for the test `orderId`.
- Exactly one call to the fake provider was recorded for that `orderId`.
- At least one `charge-settled` message was published for that `orderId`. A second
  `charge-settled` message for the same `orderId`, carrying the same terminal status,
  is acceptable and not a failure — the second delivery skips the provider call and
  republishes `charge-settled` from the existing row rather than doing nothing.

## Fail criteria

- More than one row exists in `charges` for the test `orderId`.
- More than one call to the fake provider was recorded for that `orderId`.
- No `charge-settled` message was published for that `orderId`.
- Two `charge-settled` messages for that `orderId` carry different terminal statuses.

## Cleanup

Delete the `charges` row for the test `orderId`, drain any leftover messages for it
from the charge and settled queues, and reset the fake provider's call log.

Destiny: `automate: payments integration test`
