# Orderflow — Data Model

Orderflow runs on one relational database shared by all four components, but each table in it
has exactly one component that writes to it. Rule: `orders` is written only by
`services/orders`, `charges` only by `services/payments`, `shipments` only by
`services/fulfillment`. Why: a table with two writers has no single component whose
`DESIGN.md` can promise its invariants — the writer that didn't reason about a rule can still
break it, and neither `DESIGN.md` can be trusted to describe the table's actual behavior on its
own. Every other component reaches a table it doesn't own through the owner's API or through an
event the owner publishes, never through a query or write of its own. See
[`architecture.md`](./architecture.md) for how those events and API calls connect the four
components.

## `orders`

| Column | Type | Meaning |
|---|---|---|
| `orderId` | string, primary key | The order's identifier |
| `customerId` | string | The customer placing the order |
| `amountMinorUnits` | integer | Order total, in the smallest currency unit |
| `currency` | string | Currency of `amountMinorUnits` |
| `status` | enum | `placed` \| `paid` \| `cancelled` \| `shipped` |
| `createdAt` | timestamp | When the order was placed |
| `updatedAt` | timestamp | Last time the row changed state |

Owning writer: `services/orders`. No other component queries this table directly:
`apps/web` reads order status through `GET /orders/{id}`, and `services/fulfillment` changes
`status` by calling `services/orders`' internal status-transition endpoint rather than writing
the row itself.

Integrity rules: `orderId` is the global business key — `charges.orderId` and
`shipments.orderId` both reference it, and every event in the system carries it. `status` only
moves along the lifecycle in [`architecture.md`](./architecture.md); the transition is always
requested by `services/fulfillment`, never performed by `services/orders` on its own timer.

## `charges`

| Column | Type | Meaning |
|---|---|---|
| `orderId` | string, primary key | The order this charge belongs to |
| `status` | enum | `pending` \| `succeeded` \| `declined` \| `failed` |
| `providerChargeId` | string, nullable | The payment provider's identifier for the attempt |
| `amountMinorUnits` | integer | Amount charged, in the smallest currency unit |
| `attempts` | integer | Number of provider calls made for this order |
| `updatedAt` | timestamp | Last time the row changed state |

Owning writer: `services/payments`. No other component queries this table:
`services/fulfillment` never reads `charges` — it consumes the `charge-settled` event instead,
the decision recorded in the decisions log
([`../decisions/decisions-log.md`](../decisions/decisions-log.md), entry 3) as the repo-tier
record of the same choice `services/payments`' own `DESIGN.md` makes at component tier.

Integrity rule: `orderId` as primary key enforces one charge row per order — this is the
schema fact that backs `services/payments`' `DESIGN.md` Rules & Invariants #1 (one charge per
order); a second `charge-requested` delivery for the same order can only update the existing
row, never create a second one.

## `shipments`

| Column | Type | Meaning |
|---|---|---|
| `shipmentId` | string, primary key | The shipment's identifier |
| `orderId` | string, foreign key → `orders.orderId` | The order being shipped |
| `carrier` | string | The carrier handling the shipment |
| `status` | enum | `preparing` \| `dispatched` |
| `createdAt` | timestamp | When the shipment record was created |

Owning writer: `services/fulfillment`. No other component reads or writes this table; the
`orders.status` field is how `apps/web` and everything else outside `services/fulfillment`
learns a shipment exists at all.

Integrity rule: `orderId` as a foreign key ties every shipment to exactly one order, and a
shipment is only ever created once that order has been requested to move to `paid`.
