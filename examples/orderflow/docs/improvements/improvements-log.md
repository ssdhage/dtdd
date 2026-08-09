# Improvements Log

Tracks **improvements to existing implementation** — drift, duplication, missing edge
cases, code organisation, tooling gaps. Not a feature backlog and not a design doc.

> **Next ID: IMP-003.** Assign this to the next new entry, then increment it. IDs are
> **monotonic and never reused** — retired numbers (gaps) stay retired. This counter,
> not the surviving entries, is the source of truth for the next ID (entries are
> deleted when resolved or rejected, so the highest number still in the file is not
> reliable).

## Scope

| Belongs here | Does NOT belong here |
|---|---|
| Existing code that should be cleaner, safer, more cohesive | New functionality to build |
| Bugs / edge cases the current implementation misses | Architectural design decisions |
| Refactors, dedup, structured logging, test gaps | Roadmap features |
| Path / convention mismatches with documented design | Anything tracked in a `DESIGN.md` or the decisions-log |

## How this file is maintained

- **Adding:** use the next free `IMP-XXX` ID from the `Next ID` counter, then increment
  the counter.
- **Starting work:** before touching an area, scan for an entry whose `Area` overlaps
  the files about to change and set its `Status` to `in-progress` if one matches.
- **Finishing work:** **delete the entry** in the same change that resolves or rejects
  it — there is no `resolved` status. In the same change, sweep the repository for
  references to that `IMP-XXX` and update or remove each mention elsewhere so nothing
  is left pointing at a deleted entry. This log is **transient**.

## Entries

### IMP-001: Checkout handler duplicates money-rounding logic
- **Status:** open
- **Area:** services/orders
- The checkout handler rounds order amounts in two separate branches, each with its own
  copy of the rounding logic. Extract one shared rounding helper so the two branches
  cannot drift from each other.

### IMP-002: Order-status poll has no backoff
- **Status:** open
- **Area:** apps/web
- The order-status poll retries on a fixed 1-second interval with no backoff. Add
  exponential backoff with a cap so a slow or unavailable orders API doesn't get
  hammered by every open storefront tab.
