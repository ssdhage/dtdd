# Improvements Log

Tracks **improvements to existing implementation** — drift, duplication, missing edge
cases, code organisation, tooling gaps. Not a feature backlog and not a design doc.

> **Next ID: IMP-001.** Assign this to the next new entry, then increment it. IDs are
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

Features → a future-features file. Design work → the component's `DESIGN.md`.
Decisions made → the decisions-log.

## How this file is maintained

- **Adding:** anyone can append a new entry. Use the next free `IMP-XXX` ID from the
  `Next ID` counter, then increment the counter. Confirm the entry with the relevant
  owner before adding it if the finding is not your own area.
- **Starting work:** before touching an area, scan this file for an entry whose `Area`
  overlaps the files about to change. If one matches, set its `Status` to
  `in-progress` with the date and a brief owner note.
- **Referencing in commits/PRs:** include the `IMP-XXX` ID so the link from code to
  entry is searchable (e.g. `fix(payments): handle missing currency — IMP-006`).
- **Finishing work:** **delete the entry** in the same change that resolves it — or
  that the team decides to reject. There is no `resolved` status; a resolved or
  rejected entry leaves the file. In the same change, sweep the repository for
  references to that `IMP-XXX` (search for the exact ID) and update or remove each
  mention in other docs (a `DESIGN.md`, an architecture doc, a runbook) so nothing is
  left pointing at a deleted entry. This log is **transient** — a cross-reference to a
  deleted entry must never be left dangling.

## Severity

- **critical** — actively breaking something or blocking other work
- **high** — meaningful risk (drift, silent failure, no test coverage on hot path)
- **medium** — quality / maintenance concern
- **low** — nice to have

## Entry format

Each entry:

```
### IMP-NNN: <one-line summary>
- **Severity:** critical | high | medium | low
- **Status:** open | in-progress
- **Area:** <path or component the finding is about>
- <one or more paragraphs: what the issue is, why it matters, and a suggested fix>
```

## Entries

*(none yet)*
