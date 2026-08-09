# apps/web — Design & Decision Log

`apps/web` is the browser storefront a shopper uses to place an order and watch it move
through to shipment. Start reading at `src/main.tsx` (app bootstrap and routing), then
`src/checkout-page.tsx` (the checkout form and the order-status view), then
`src/api-client.ts` (the HTTP calls to `services/orders`).

## Why This Exists

A shopper needs one place to submit a cart and find out what happened to it, without knowing
that an order is finalized by one service, charged by another, and shipped by a third. `apps/web`
is that place: it collects checkout input, submits it once, and then shows the shopper their
order's status as it changes — `placed`, `paid`, `cancelled`, `shipped` — without the shopper
ever seeing the queue, the charge, or the shipment record behind those words.

## What This Does

The checkout page collects cart items and a tokenized payment method, then submits a single
`POST /orders` request to `services/orders`. On a successful response it stores the returned
`orderId` and switches to the order-status view.

The order-status view polls `GET /orders/{id}` on `services/orders` and renders the `status`
field it returns as one of four states: `placed` ("order placed, payment in progress"), `paid`
("payment received"), `cancelled` ("payment declined"), or `shipped` ("order shipped"). It does
not compute any of these states itself — it only maps the API's `status` value to a message.

## How It Works

1. The shopper fills out the checkout form and submits it.
2. `api-client.ts` sends `POST /orders` to `services/orders` with the cart items and the
   tokenized payment method; it does not send a total.
3. On a `202 Accepted` response, `checkout-page.tsx` stores the `orderId` and starts polling
   `GET /orders/{id}` on a fixed interval.
4. Each poll response updates the rendered status. The page keeps polling as long as the status
   is `placed`.
5. A `paid`, `cancelled`, or `shipped` response is terminal for this view — the poll loop stops
   and the final state stays on screen.

## Boundaries

`apps/web` talks only to the `services/orders` HTTP API, over HTTPS. It has no queue access and
no database access — every fact it shows about an order comes from a `services/orders` response,
never from a direct read of any table. It does not price a cart or compute a total; it displays
whatever amount and currency `services/orders` returns, and submits only the raw cart items for
`services/orders` to price.

## Rules & Invariants

1. **The client never computes or submits a total.** The checkout form sends cart items and a
   payment method token; it has no total field to send. Rule: pricing is not client state, ever.
   Why: a total computed in the browser can be edited in the browser — the price a shopper is
   charged must come only from the server that owns pricing.
2. **A terminal status stops the poll loop.** The order-status view keeps calling
   `GET /orders/{id}` only while the returned status is `placed`; a response of `paid`,
   `cancelled`, or `shipped` ends the loop. Rule: no view keeps polling an order that will never
   change state again. Why: `placed` is the only status this app expects to see change under it —
   polling past a terminal status would just be wasted requests against an answer that is
   already final.
3. **The app never sees raw payment instrument data.** The provider's browser SDK collects card
   details and exchanges them for an opaque token before the checkout form ever submits
   anything; `apps/web` code only ever holds that token. Rule: no card number, expiry, or CVV
   passes through this app's own code at any point. Why: the token is meaningless outside the
   provider, so even a bug in this app's own logging or error handling cannot leak a usable card
   number.

## Key Design Decisions

1. **The order-status view polls `GET /orders/{id}` on an interval rather than opening a
   websocket to `services/orders`.** A status change happens at most a few times over an
   order's lifetime and each one is already slow relative to a poll interval — a websocket
   would hold a persistent connection open for updates that arrive rarely. The rejected
   alternative, a websocket or server-push channel, was dropped because it adds a stateful
   connection to maintain for a small number of infrequent updates that a poll already
   delivers within one interval's latency.

## Deliberately Left Out

- **An order-history or past-orders list.** `apps/web` shows the one order just placed; it does
  not list or search prior orders for a customer. Reason: browsing past orders needs pagination
  and filtering that the current single-order checkout flow has no use for.
- **Handling or displaying raw payment instrument data.** The provider's browser SDK tokenizes
  card details before this app receives anything. Reason: there is no code path in this app that
  ever holds a raw card number, so there is nothing here to build for it.

## Configuration

| Variable | Purpose | Default |
|---|---|---|
| `ORDERS_API_BASE_URL` | Base URL of the `services/orders` HTTP API this app calls | none — required at build time |
| `ORDER_STATUS_POLL_INTERVAL_MS` | Interval between `GET /orders/{id}` polls on the status view | `1000` |

## Open Questions

None — no open questions.

## Next Steps

The order-status poll retries on a fixed interval with no backoff; adding exponential
backoff with a cap is the planned improvement (see IMP-002 in the improvements log).

## Related Documents

- [`../../docs/architecture/architecture.md`](../../docs/architecture/architecture.md) — platform-wide architecture
- [`../../services/orders/DESIGN.md`](../../services/orders/DESIGN.md) — the API this app calls
