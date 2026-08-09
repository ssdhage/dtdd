# CLAUDE.md — Orderflow

## Reading Priority

Read the relevant `DESIGN.md` before touching any component: `services/orders/DESIGN.md`,
`services/payments/DESIGN.md`, `services/fulfillment/DESIGN.md`, or `apps/web/DESIGN.md`.
Read `docs/architecture/architecture.md` and `docs/architecture/data-model.md` before any
change that touches more than one component. Code exists to verify the docs, never to replace
them. When a `DESIGN.md` and its code disagree, flag the discrepancy and resolve it in the
doc, deliberately — never patch the doc silently to match whatever the code happens to do.

## Present-State Discipline

Every doc except the two logs describes the system as it is today — no changelog verbs
(`replaced`, `removed`, `previously`, `no longer`), no dates. History lives only in
`docs/decisions/decisions-log.md` and `docs/improvements/improvements-log.md`. A `DESIGN.md`
or architecture doc never leans on an `IMP-XXX` entry as its explanation — a limitation is
stated self-contained, in the present, so the sentence still reads correctly after that entry
is resolved and deleted from the improvements log.

## Shared-Code Consumption

Orders, payments, fulfillment, and the web app are separately deployed services. A service
never reads another service's table and never imports another service's internals. The
`orders`, `charges`, and `shipments` tables each have exactly one writer (see
`docs/architecture/data-model.md`); every other component reaches that data only through the
owning component's HTTP API or its published queue events (`charge-requested`,
`charge-settled`).

## Document Ownership

- A component's code, tests, and `DESIGN.md` belong to whoever is changing that component.
- `docs/architecture/`, `docs/decisions/`, `docs/improvements/`, and the root `README.md`
  belong to whoever is reasoning about the cross-component change, updated at the point the
  change lands.
- `docs/templates/DESIGN.template.md` and this file change only with explicit human approval.

## Review Gates

Before any commit, the design-sync review runs in an independent context — never inline in
the session that authored the diff — and creates the single-use commit stamp the commit gate
requires; without that stamp, the commit is blocked. Convention, security, and correctness
reviews run at the pull-request boundary, each checking a distinct, non-overlapping concern.
The commit decision itself is always a human's.
