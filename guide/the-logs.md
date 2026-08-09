# The Logs

The Fact (see [methodology.md](methodology.md)) is present-state only — a `DESIGN.md`
describes what a component *is*, never what it *used to be*. History has to live
somewhere, or it's simply lost. It lives beside the Fact, in two logs, and the two are not
interchangeable.

## Fact ≠ Narrative

This is ideology 2 of the methodology: present-state docs are the Fact; the logs are the
narrative of change. Splitting them is what stops the Fact from rotting into a changelog —
a `DESIGN.md` that accumulates "replaced X with Y on <date>" sentences is no longer
present-state, it's a diary wearing a design doc's name. Every fact about *why* something
changed, or *what was tried and rejected*, goes in a log instead. Two logs, because history
splits cleanly into two kinds with different lifetimes.

**Canonical locations.** Each log lives in its own folder under `docs/`:
`docs/decisions/decisions-log.md` and `docs/improvements/improvements-log.md` (this is what
`/dtdd-init` scaffolds, and the path the commit gate's dangling-reference check watches). A
folder per log is deliberate — each can accrue siblings with the same lifetime (superseded
decision attachments beside the permanent log; per-area improvement notes beside the
transient one) without mixing the two lifetimes in one directory.

## `decisions-log.md` — permanent, append-only, the only home of history

This is where a confirmed decision is recorded **on its own terms**: what was decided, what
alternatives were considered and rejected, and why. Once written, an entry is never edited
to track the current code — if a decision is later reversed, a *new* entry records the
reversal; the old entry stays, because it's true that the decision was made and true that it
was later changed. The log is a timeline, not a mirror of today's state.

A typical entry, generic form:

```
**Retry policy: exponential backoff, capped at 5 attempts**
Considered a fixed retry count with linear delay. Rejected because a downstream
outage produces a retry storm at a fixed interval. Landed on exponential backoff
(base 200ms, cap 5 attempts) so retries space themselves out automatically.
```

Notice what's absent: no ticket ID, no run ID, no "as of Q3" — the entry is self-contained
and ordered by its position in the log. One exception: an entry that supersedes an earlier
one carries a date prefix in its title, so the reversal's ordering survives even a later
reorganization of the file. It records a decision, not a task.

**A decision is recorded on its own terms** — its substance and rationale stand whether or
not an improvement-log entry ever tracked the problem. The decisions-log **never cites an
`IMP-XXX`**: see the dependency-direction rule below.

## `improvements-log.md` — transient, entries deleted on resolution

This is a tracker for improvements to the **existing** implementation — drift, missing edge
cases, duplication, tooling gaps. It is explicitly **not** a feature backlog and **not** a
design doc: a new capability belongs in a plan or a `DESIGN.md`'s open questions, not here.

**IDs are monotonic and never reused.** Each entry gets `IMP-<n>` from a **Next-ID counter**
kept in the log's header — not by scanning the file for the highest number currently
present, because entries are deleted once resolved, so the highest surviving number
understates history. The counter, incremented every time an ID is issued, is the only
source of truth for what's next.

**Status lifecycle:** `open` → `in-progress` (owner + date noted on the entry) → **deleted**.
There is no `resolved` status — an entry that's done doesn't get marked done, it leaves the
file. The log only ever shows what's still outstanding.

Three lifecycle rules keep the log honest as work flows through it:

- **Scan before work.** Before touching an area, check the log for an entry whose scope
  overlaps the files about to change. If one exists, mark it `in-progress` rather than
  duplicating the same finding under a new ID.
- **Cite in commit.** When work resolves an entry, the commit message references its
  `IMP-<n>` so the link from code history to the tracker is searchable later — even though
  the entry itself is about to disappear from the log.
- **Sweep references on delete.** Deleting an entry is not just removing its block from the
  log. Grep the repo for that ID (docs, comments, other logs) and fix every dangling
  reference in the *same* change. A citation to a deleted entry is worse than no citation —
  it points a future reader at nothing.

Example entry, generic form:

```
### IMP-012: retry logic duplicated across the payments client and the
email-sender client
- **Severity:** medium
- **Status:** open
- **Area:** `payments/client`, `email-sender/client`
- Both clients hand-roll the same exponential-backoff loop. Extract one shared
  retry helper; both callers adopt it.
```

## The lifecycle-aware dependency direction rule

This is ideology 3, and it is the load-bearing rule that makes the split safe: **a permanent
artifact never points at a transient one.**

- The `decisions-log.md` never cites an `IMP-<n>` — a decision's substance doesn't depend on
  a tracker entry that might not exist tomorrow.
- A `DESIGN.md` sentence *may* cite an `IMP-<n>` as an optional pointer to more detail, but
  the sentence must still read correctly and completely if that entry is deleted the next
  day. State the current limitation in the present tense first (self-contained); the
  `IMP-<n>` citation, if present at all, is decoration on a fact that already stands without
  it — never the explanation itself.
- No document or piece of code cites a run ID, a seam ID, or a ticket ID from the process
  that produced it. Those identifiers belong to a task-tracking system outside the repo, and
  a task tracker is even more transient than the improvements-log — it can be migrated,
  renamed, or shut down entirely without the repo knowing. A repo fact that depends on an
  external tracker's ID for its meaning is a fact that can silently go stale.

The direction only ever runs one way: transient artifacts may reference permanent ones (an
`IMP-<n>` entry can say "see the decisions-log entry on retry policy"), but never the
reverse. A permanent record that depended on a transient one would inherit that transient
one's mortality.

## Where this shows up elsewhere

- [methodology.md](methodology.md) states ideologies 2 and 3 in one line each; this doc is
  their full worked-out rule.
- [the-loop.md](the-loop.md) — the worker's step 6 (finalize the canonical `DESIGN.md`) is
  where a design decision surfaced during implementation gets written up here, not left as
  a comment in code.
- [design-docs.md](design-docs.md) covers the sibling discipline for present-state docs
  themselves: explicit absence, no changelog verbs, no provenance.
- [review-gates.md](review-gates.md) — the design-sync lens is the one that mechanically
  sweeps dangling `IMP-<n>` references when an entry is deleted, as part of its pre-commit
  check.
