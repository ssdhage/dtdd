# The Repo Fact

A component's `DESIGN.md` states what that one unit does. Nothing in any single component's
doc can state how a payments service's output becomes an email-sender's input, what the
shared data model looks like across every component that touches it, or how a request flows
end to end through five services on its way to a response. That cross-component truth is the
**Repo Fact** — the second tier of the Fact model, sitting above every individual Component
Fact. This document covers what belongs in it, the order in which it gets read, and what
happens when it stops matching the code.

See [`methodology.md`](./methodology.md) for the Fact model both tiers belong to, and
[`design-docs.md`](./design-docs.md) for the per-component tier this one sits above.

---

## What lives at this tier

The Repo Fact holds anything that spans more than one component and would have to be
duplicated — or worse, left inconsistent — if each component tried to state its own copy:

- **Architecture** — how the components fit together, what calls what, and why the system is
  shaped the way it is.
- **Shared data model** — a schema, message format, or data contract more than one component
  reads or writes, stated once in a shared location rather than re-described per consumer.
- **Business flows** — an end-to-end path through the system (a request, a job, an event)
  that no single component's `DESIGN.md` can narrate on its own, because the flow's meaning
  only exists at the point where components hand off to each other.
- **Shared conventions** — a testing strategy, a naming scheme, a cross-cutting policy that
  every component follows but that belongs to none of them individually.

Rule: **if a fact is true of exactly one component, it lives in that component's
`DESIGN.md`; if it is true across components, or is only meaningful at the boundary between
them, it lives in the Repo Fact.** Why: a cross-component fact stated redundantly inside two
or three components' docs will drift the first time only one of those docs gets updated — the
Repo Fact tier exists so that fact has exactly one home, and updating it updates it everywhere
it's read from.

The Repo Fact is present-state, exactly like a component's `DESIGN.md`: no changelog verbs, no
dates, no narrating how the architecture got this way. The reasoning behind a cross-cutting
decision is recorded in the decisions log, not narrated inline in the architecture doc itself.

---

## Reading priority

Docs are read before code, and in a fixed order, because each tier answers a narrower
question than the one before it:

1. **The component's `DESIGN.md`** — read first, always, when about to touch anything inside
   that component. It is the primary context for that unit and the only place its internal
   contract is stated.
2. **The Repo Fact** (architecture, shared data model, business flows) — read before making
   any suggestion or change that crosses component boundaries, or before touching a shared
   schema more than one component depends on.
3. **Other supporting docs** — anything the `DESIGN.md` or the Repo Fact points to (a
   deeper schema doc, a runbook, a decisions-log entry) — read as referenced, not
   speculatively.
4. **Code** — read *only* to verify that the implementation still matches what the docs
   claim. Code is never read as the source of design intent; if a reader needs to know *why*
   something is built a certain way, that answer lives in a doc, and if it doesn't, the doc
   is missing something rather than the code being the fallback source of truth.

Rule: **always read the `.md` files first; code is for verification only.** Why: code
answers "what does this do right now" but not "what is this supposed to do" or "what was
considered and rejected" — those answers only exist in prose. An agent that derives intent
from code alone will faithfully reproduce whatever the code currently does, including its
bugs and its accidents, because code cannot distinguish a deliberate invariant from an
incidental implementation detail. Reading docs first is what lets an agent tell the
difference before it decides a change is safe to make.

---

## When a doc and the code disagree

A discrepancy between what a `.md` file says and what the code actually does is never
resolved by quietly editing the code to match the doc, and never resolved by quietly editing
the doc to match the code. Both are silent fixes, and both destroy information: silently
changing the code assumes the doc's intent should win without checking whether the code was
actually a deliberate, undocumented change in intent; silently changing the doc assumes the
code's current behavior is correct without asking whether it's actually a drifted bug.

Rule: **a doc-versus-code mismatch is flagged, not resolved unilaterally — decide with the
project's owner which one is correct, then update every affected doc to reflect the agreed
design before touching the code.** Why: whichever side is "right" is a design question, not a
mechanical one, and design questions get decided deliberately, not defaulted to whichever
artifact happens to be easier to edit in the moment. Silently patching code to hide a doc
mismatch is exactly the failure mode the Fact model exists to prevent — a doc that no longer
describes reality is worse than no doc, because it actively misleads the next reader who
trusts it.

---

## Who owns the Repo Fact

A component's `DESIGN.md` is written by the worker that changed that component — the actor
that did the reasoning for that one unit. The Repo Fact is different: it spans components, so
no single component worker is positioned to update it correctly, and it is owned instead by
the tier doing the cross-component reasoning — the orchestrator that scoped the whole
change, decided which components are affected, and saw the change complete across all of
them.

The orchestrator writes (or updates) the Repo Fact at **fan-in** — after every affected
component has finished its own loop and reported back, not before, and not incrementally as
each component lands. Writing it once, at the end, against the change as it actually landed
across every component, avoids describing a cross-component flow that's only half-built.
Shared logs that grow by append (a decisions log, an improvements log) are updated serially at
this same point, never clobbered by two components' changes landing out of order.

Rule: **document writes stay with the reasoning actor** — a component detail is written by
the component worker that reasoned about it; a cross-component fact is written by the
orchestrator that reasoned across components; a fixed template or a root-level convention
file is written by neither, and changes only with explicit human approval. Why: an actor
writing a doc tier it didn't reason about is guessing, and a guess recorded as Fact is
indistinguishable from a verified one until the next reader trusts it and is wrong.

See [`the-loop.md`](./the-loop.md) for the worker loop and fan-in sequence this ownership
rule is part of, and [`design-docs.md`](./design-docs.md) for the component tier the Repo Fact
sits above.
