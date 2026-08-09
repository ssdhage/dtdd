# Component DESIGN.md discipline

Every component in the repo — a service, a job, a shared package, a frontend app — carries
exactly one `DESIGN.md`. This is the **Component Fact**: the present-state contract for that
one unit, read first by anyone (human or agent) about to change it, and written last by
whoever changes it. This document covers what the file is for, the fixed shape it must take,
and the timing rule that keeps it honest.

See [`methodology.md`](./methodology.md) for the Fact model this tier belongs to, and
[`repo-docs.md`](./repo-docs.md) for the sibling tier — the cross-component truth no single
`DESIGN.md` can hold.

---

## What a DESIGN.md is

A `DESIGN.md` is not documentation *about* the component — it is the component's contract,
in prose. It states what the component does, how it works, what must remain true of it, and
what was deliberately not built. An agent about to touch the component reads this file
*instead of* reading the component's internals to understand intent; the code is read only
afterward, to verify the file's claims still hold.

This gives the file two readers with different needs, both served by the same text:

- **A human** reviewing a change diffs the `DESIGN.md` against their mental model of the
  component and immediately sees what moved.
- **An agent** starting a task parses the file's fixed sections as a schema, not free text —
  it can jump straight to "Rules & Invariants" or "Boundaries" without reading everything.

Rule: **the component's `DESIGN.md` is read before its code, and is the substrate a worker
reasons from — not a summary written after the fact.** Why: a summary written after the code
already exists tends to describe what the code happens to do, not what it must do; a contract
read *before* the change is what keeps the change accountable to something other than itself.

---

## The fixed template (one grammar, many components)

Every `DESIGN.md` in the repo uses the same section list, in the same order, regardless of
whether the component is a backend service, a shared library, or a frontend app. The shipped
template lives at [`../templates/DESIGN.template.md`](../templates/DESIGN.template.md), and
fully worked specimens live in the Orderflow example — start with
[`../examples/orderflow/services/payments/DESIGN.md`](../examples/orderflow/services/payments/DESIGN.md),
and see [`../examples/orderflow/README.md`](../examples/orderflow/README.md) for where every
document tier sits in a whole repo. Read one specimen before writing your first doc — it
answers most "what does a good one look like" questions. The section list is, in order:

1. Header preamble (unnamed) — what the component is, in one sentence, and where to start
   reading its entry-point files.
2. Why This Exists
3. What This Does
4. How It Works
5. Boundaries
6. Rules & Invariants
7. Key Design Decisions
8. Deliberately Left Out
9. Configuration
10. Open Questions
11. Next Steps
12. Related Documents

Rule: **the section list is a grammar, not a suggestion — a section that does not apply to
this component still appears, with a one-line stated reason for its absence** (see below).
No component's `DESIGN.md` skips a section because "it doesn't apply here"; it says so.

Why a fixed shape at all, rather than letting each component's doc take whatever form suits
it: a bespoke structure optimizes for the one component it was written for and costs every
future reader — human or agent — the work of re-learning where things live each time they
open a new file. A fixed grammar means "where are this component's invariants" has the same
answer everywhere: the "Rules & Invariants" section, always in the same position. An agent
parsing a hundred components' docs across a repo-wide change reads them as one schema, not a
hundred idiosyncratic essays. A human doing the same review diffs section-by-section instead
of hunting for where the equivalent content landed this time. The template is what makes the
"read the design doc first" rule cheap enough to actually follow.

---

## Explicit absence

A section that has nothing to say for this component is never dropped from the file. It
stays, with a one-line body: `None — <reason>.` — for example, a component with no runtime
configuration keeps the "Configuration" heading with `None — no runtime configuration.`
underneath it, rather than omitting the heading.

Rule: **an empty section is a statement, never an omission.** Why: a missing heading is
ambiguous — did nobody write it, or does nothing belong there? A one-line `None — <reason>.`
answers that question on sight, and it means a reader can trust that every present heading
was actually considered for this component, not skipped by oversight. The same pattern
extends past `DESIGN.md` itself: a skipped test names what it did not exercise, and a
rejected design is recorded rather than left for a future reader to silently re-propose.
Absence that isn't stated is indistinguishable from absence nobody noticed.

---

## Present-state only

A `DESIGN.md` describes the component **as it currently is** — never as a record of how it
got that way. It uses no changelog verbs (`replaced`, `removed`, `no longer`, `previously`,
`migrated from`, `deprecated`), no dates, and never defines the present by the absence of a
past state (not "no longer reads from the old store" — just state what it reads from now).

Rule: **the Fact (present-state docs) and the Narrative (the logs recording change over
time) are two different documents, and only the logs carry history.** A decision this
component's design reflects — and the alternative that lost — belongs in the "Key Design
Decisions" section of *this* file, stated as current reasoning ("this component does X, not
Y, because…"), not as a dated before-after entry; the dated record of *when* that decision
was made lives in the repo-wide decisions log, never here.

Why: a doc that mixes "what is true now" with "what used to be true" rots the moment the next
change lands — every future edit has to decide whether to update the old narrative too, and
most edits don't. A doc that only ever states the present needs no such judgment call: the
last edit is always correct, because it never claimed to describe anything but the current moment.
This is what lets an agent trust a `DESIGN.md` it has never seen before without independently
verifying every sentence against git history first.

A `DESIGN.md` also never cites *how* a change was produced — no run identifier, no generator
or skill name, no link to a scratch spec or discussion thread that produced the current text.
It states the fact the change left behind, not the process that produced it. Why: a fact
that depends on a transient run for its meaning stops being self-contained the moment that
run is forgotten; a permanent doc must read correctly on its own, indefinitely.

---

## Read-first, write-last

Both the timing of a `DESIGN.md` read and its write are load-bearing, not incidental:

- **Read first.** Before any change to a component, its `DESIGN.md` is read before its code.
  The reader decides one of three outcomes: the design is unchanged (proceed straight to
  tests), the design needs a change (proceed, planning to update this file at the end), or
  the design is compromised — the file no longer describes reality and the change cannot
  safely proceed on top of it (stop and escalate rather than guess).
- **Write last.** The canonical `DESIGN.md` is updated once, after the code change is
  implemented and tests pass — never drafted early and left to drift while the
  implementation is still in flux, and never edited twice (once as a guess, again as a
  correction).

Any intermediate notes about the design delta — a working sketch of what's about to change —
stay outside this file, in a scratch location that gets discarded once the canonical file is
updated. The `DESIGN.md` itself only ever holds the current, settled state.

Rule: **the canonical doc is written once, against reality.** Why: a doc updated before the
code exists describes an intention, which may not survive contact with implementation; a doc
updated twice (draft, then correction) means the interim state was published as fact when it
wasn't one yet. Writing it once, last, against code that has already been built and tested,
is what keeps "the `DESIGN.md` is true" a statement a reader can rely on rather than one they
have to double-check.

---

## Who writes it

The `DESIGN.md` is owned by whoever did the reasoning for that change to that component —
never delegated downward to a cheaper pass just because the writing itself is mechanical.
The reasoning that produced the change is the reasoning qualified to state its result; a
paraphrase written by an actor that didn't do the reasoning risks restating an intention
the actual implementation didn't fully honor.

See [`the-loop.md`](./the-loop.md) for where this fits in the worker loop end to end, and
[`repo-docs.md`](./repo-docs.md) for the cross-component tier this file's "Related Documents"
section points into.
