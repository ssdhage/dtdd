# Decisions Log

A chronological, append-only record of confirmed decisions — architectural, product,
or process. Entries are added as decisions are made; they are never edited to erase
what was decided, only appended to when a later decision supersedes an earlier one.
This file is the **narrative** layer: unlike a `DESIGN.md` (which is present-state
only), a decisions-log entry may say "was X, now Y" and may carry a date, because
recording *that a change happened, and why* is exactly this file's job.

A decision is recorded **on its own terms** — its substance and its rationale — whether
or not an improvement tracker happened to flag the same area first. This file never
cites an `IMP-XXX` improvements-log entry or any other transient identifier: a
permanent record must not point at something that can later be deleted out from under
it (see the improvements-log's own lifecycle rules). If context from a transient log
matters to a decision, that context is restated here in the decision's own words, not
referenced by ID.

## Entry format

- **Grouping.** Entries are grouped under a level-2 heading naming the area the
  decisions in that group belong to (e.g. `## Payments Service`, `## Data Model`,
  `## Authentication`). A new area gets a new heading; an existing area's later
  decisions are appended under its existing heading, in the order they were made.
- **No numeric ID scheme.** Entries are identified by their bold title line, not by a
  monotonic ID like the improvements-log's `IMP-XXX`. Nothing elsewhere in the
  repository needs to reference "decision #14" — a `DESIGN.md` describes the current
  design directly, and this log is read start-to-finish or grepped by title/keyword,
  never looked up by number.
- **Title line.** Each decision opens with a short, bold, one-line title stating the
  decision itself (e.g. `**Requests are retried with arithmetic backoff**`). When an
  entry supersedes or narrows an earlier entry in the same group, prefix the title
  with a date — `**YYYY-MM-DD — <title>**` — and name the earlier decision inline in
  the prose ("This supersedes the earlier decision that …"). A first-time decision
  with no predecessor carries no date.
- **Body.** One paragraph (or a few, for a decision with several moving parts)
  covering, in order: what was decided, stated plainly; the rationale — why this and
  not something else; and the alternative(s) considered and rejected, with the reason
  they lost (a single clause is enough when the reason is obvious).

## Entries

*(none yet)*
