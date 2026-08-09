<!-- Part of the Orderflow worked example (see ../../README.md): the 12-section DESIGN.md -->
<!-- template filled in for a fictional queue-consuming payments-charging worker. The -->
<!-- component is invented for illustration; the documentation discipline it demonstrates is not. -->

# services/payments — Design & Decision Log

`services/payments` is a queue-consuming service that charges customers through a third-party
payment provider and records the outcome of each charge. Start reading at `src/consumer.ts`
(queue poll loop and message dispatch), then `src/charge.ts` (idempotency check, provider
call, result persistence), then `src/provider-client.ts` (the HTTP client wrapping the
provider's charge API).

## Why This Exists

An order becomes payable the moment its total is finalized, but the checkout request that
finalizes it must return to the shopper immediately — it cannot hold the connection open for
however long a card network takes to authorize a charge. Something has to sit between "order
is ready to be charged" and "charge is settled and the order can move to fulfillment,"
absorbing provider latency and provider failures without losing the order or charging it
twice. `services/payments` is that something: it turns a fire-and-forget charge request into a
durable, retried, exactly-once-effect operation.

## What This Does

The worker consumes `charge-requested` messages from a queue, one per order, shaped as:

```json
{
  "orderId": "ord_8f3a1c",
  "customerId": "cus_2b91",
  "amountMinorUnits": 4999,
  "currency": "USD",
  "paymentMethodToken": "pm_tok_9e21"
}
```

For each message it produces exactly one row in the `charges` table, in one of three terminal
states (`succeeded`, `declined`, `failed`) or the transient state `pending` while a provider
call is in flight. It exposes no HTTP endpoint of its own; its only outputs are that row and,
on success, a `charge-settled` event published back onto a queue for downstream consumers.

| Field | Type | Meaning |
|---|---|---|
| `orderId` | string, primary key | The order this charge belongs to |
| `status` | enum | `pending` \| `succeeded` \| `declined` \| `failed` |
| `providerChargeId` | string, nullable | The provider's own identifier for the charge attempt |
| `amountMinorUnits` | integer | Amount charged, in the smallest currency unit |
| `attempts` | integer | Number of provider calls made for this order |
| `updatedAt` | timestamp | Last time the row changed state |

## How It Works

```mermaid
flowchart TD
    proc["poll queue"]
    msg["charge-requested"]
    check{"row exists?"}
    call["call provider"]
    db[("charges table")]
    ok["mark succeeded"]
    no["mark declined"]
    err["mark failed, retry"]
    dlq[("dead-letter queue")]
    out[("settled queue")]

    proc --> msg --> check
    check -->|no| call
    check -->|yes, terminal| out
    call --> db
    db --> ok --> out
    db --> no
    call -->|provider error| err --> dlq

    classDef store fill:#1e3a5f,stroke:#5b9bd5,color:#fff;
    classDef proc fill:#2d5a3d,stroke:#7bc47f,color:#fff;
    class proc proc;
    class db,dlq,out store;
```

1. The worker polls the queue and receives one `charge-requested` message.
2. It looks up the `charges` row for `orderId`. If a row already exists in a terminal state
   (`succeeded` or `declined`), the worker skips the provider call entirely, republishes
   `charge-settled` from the existing row, and acknowledges the message — this is what makes
   redelivery safe.
3. If no row exists, it inserts one in `pending` state, then calls the provider's charge
   endpoint, passing `orderId` as the provider's own idempotency key.
4. A `succeeded` or `declined` response from the provider is written to the row as a terminal
   state and `charge-settled` is published.
5. A network error, timeout, or 5xx from the provider leaves the row in `pending`, increments
   `attempts`, and the message is retried with exponential backoff (base 2 seconds, doubling,
   capped at 5 attempts).
6. A message that exhausts its retries is moved to a dead-letter queue rather than retried
   indefinitely; the row stays `pending` for manual investigation rather than being marked
   `failed` automatically, since the provider call may have actually succeeded without the
   response reaching the worker.

### Retry and backoff

Retries apply only to the transport call to the provider, never to the queue message as a
whole being reprocessed from scratch — each retry reuses the same `orderId` idempotency key,
so a retried attempt and the original attempt collapse into the same provider-side charge
rather than producing two charges.

## Boundaries

The worker has one upstream producer and one downstream consumer, plus one external
dependency:

- **Upstream producer:** the order service publishes `charge-requested` once an order's total
  is finalized. The worker trusts the message's `amountMinorUnits` and `currency` as final —
  it does not recompute the order total, and it does not know how the order was priced.
- **Downstream consumer:** the fulfillment service subscribes to `charge-settled` and moves an
  order to the next stage on `succeeded`, or to a cancellation flow on `declined`. The worker
  does not know what fulfillment does with the event; its contract ends at publishing it.
- **Provider dependency:** the worker calls one external payment provider's HTTP API using
  short-lived credentials injected at startup. It does not persist card numbers, CVVs, or any
  other raw payment instrument data — it holds only the opaque `paymentMethodToken` the
  upstream service already tokenized, and the provider's own `providerChargeId`.

The consumer loop and the provider client are separate layers: the consumer loop knows about
queues and message acknowledgment and must NOT know the shape of the provider's request or
response; the provider client knows how to call the provider and must NOT know where the
`orderId` it's charging came from. This split is what lets the provider client be tested
against a fake provider without a queue running at all.

## Rules & Invariants

1. **One charge per order.** The `charges` table has `orderId` as its primary key, and every
   write path uses an upsert keyed on `orderId` rather than an insert. Rule: a given order can
   occupy at most one row, ever. Why: the queue's at-least-once delivery guarantees the same
   `charge-requested` message can arrive twice; without a single row per order the second
   delivery would create a second charge and the customer would pay twice.
2. **The provider idempotency key is the order ID, not a per-attempt identifier.** Rule: every
   provider call for a given order — the first attempt and every retry — passes the same key.
   Why: the provider's own idempotency handling is the last line of defense if the worker's
   own state got out of sync (for example, a crash between "provider call succeeded" and "row
   written"); reusing the key means even a lost acknowledgment resolves to one real-world
   charge, not two.
3. **A row in `pending` is never treated as failed on retry exhaustion.** Rule: exhausting
   retries moves the message to the dead-letter queue and leaves the row as `pending`; it does
   not overwrite the row to `failed`. Why: "no response from the provider" is not the same
   fact as "the provider declined the charge" — the charge may have gone through on the
   provider's side even though the worker never learned about it, and marking it `failed`
   would let a duplicate charge attempt slip in later under the false belief that no charge
   exists yet.

## Key Design Decisions

1. **The worker keys idempotency on the order, not on the queue message.** A queue message ID
   changes on every redelivery, so keying on it would treat each redelivery as a new charge
   attempt with no memory of prior ones. Keying on `orderId` instead makes idempotency a
   property of the business entity being charged, which is stable across any number of
   redeliveries. The rejected alternative — deduplicating on message ID at the queue's
   consumer-group layer — was dropped because it only protects against the queue redelivering
   the *same* message; it does nothing if the order service itself publishes the request
   twice, which the order-ID key also covers for free.
2. **Failed provider calls hold the row at `pending` rather than writing a `failed` status
   immediately.** This trades a slightly slower failure signal to fulfillment for the
   guarantee that "unknown outcome" and "confirmed declined" are never confused in the data.
   The rejected alternative — writing `failed` on any provider error and letting a
   reconciliation job correct it later — was dropped because it introduces a window where a
   customer could see a second charge attempt succeed while the first is still genuinely
   in flight on the provider's side.
3. **The worker publishes `charge-settled` itself rather than having fulfillment poll the
   `charges` table.** This keeps fulfillment decoupled from the payments schema entirely — it
   never runs a query against a table it doesn't own. The rejected alternative, a shared read
   replica fulfillment queries directly, was dropped because it would let a schema change to
   `charges` silently break an unrelated service.

## Deliberately Left Out

- **Partial refunds and multi-capture flows.** The provider API supports capturing less than
  the authorized amount and issuing partial refunds; the worker only ever captures the full
  authorized amount in a single call. Reason: no current caller needs a partial capture, and
  adding it would require the `charges` row to track a running captured total instead of a
  single terminal amount, which the rest of the schema is not shaped for.
- **Multi-currency conversion.** The worker charges in whatever currency the message specifies
  and does not convert between currencies. Reason: currency selection is a pricing decision
  that belongs to the order service, not to the component that executes the charge.

## Configuration

| Variable | Purpose | Default |
|---|---|---|
| `PROVIDER_API_KEY` | Credential the provider client authenticates with | none — required at startup |
| `PROVIDER_BASE_URL` | Base URL of the provider's charge API | none — required at startup |
| `CHARGE_QUEUE_URL` | Queue the worker polls for `charge-requested` messages | none — required at startup |
| `MAX_CHARGE_ATTEMPTS` | Number of provider-call retries before dead-lettering a message | `5` |

## Open Questions

None — no open questions.

## Next Steps

None — no near-term work planned.

## Related Documents

- [`../../docs/architecture/architecture.md`](../../docs/architecture/architecture.md) — the
  system flow this worker sits in the middle of, and the repo-tier one-writer-per-table rule
  behind the `charges` ownership.
- [`../../docs/architecture/data-model.md`](../../docs/architecture/data-model.md) — the
  `charges` table this worker owns, beside the tables it must never write.
- [`../orders/DESIGN.md`](../orders/DESIGN.md) — the upstream producer of `charge-requested`.
- [`../fulfillment/DESIGN.md`](../fulfillment/DESIGN.md) — the downstream consumer of
  `charge-settled`.
