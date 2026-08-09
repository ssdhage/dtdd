# Runbooks

A runbook is an **executable test scenario written as a document** — a sequence a human or an
AI agent can follow step by step, with no prior context beyond what the document states, that
exercises real behavior of the running system and reports a clear pass or fail. This document
covers what a runbook scenario must contain, the "proves" linkage that ties it back to the
design, the destiny tag that says what should eventually happen to it, and where runbooks sit
relative to the Fact.

See [`testing.md`](./testing.md) for the automated-test counterpart (unit and self-contained
integration tests), and [`design-docs.md`](./design-docs.md) for the invariants a runbook
proves.

---

## Why runbooks exist

Some behavior is real, important, and expensive or impractical to assert with an automated test
— a multi-process flow across independent services, a failure mode that only appears against a
live external dependency, a timing-dependent recovery path. An automated suite either can't
reach this behavior at all, or can only reach it by simulating so much of the real environment
that the simulation itself becomes the thing worth doubting.

A runbook fills that gap: it is a **precise, repeatable, falsifiable procedure**, expressed in
prose and commands, that a person or an agent runs against the real system and reports against
explicit pass/fail criteria — not a vague manual QA checklist, but something exact enough that
running it twice produces the same verdict.

---

## Anatomy of a scenario

Every runbook scenario is a single, independently runnable unit. It states its own delta on top
of a shared base environment, gives exact commands, defines pass/fail precisely, and cleans up
after itself — so any scenario, any subset, or the whole file can run in any order without one
scenario's leftovers corrupting the next.

A scenario has these parts, in order:

1. **A short identifier and title** — stable enough to reference from a report or a commit
   message (e.g. `S-04 — Duplicate delivery of a completed unit of work is skipped`).
2. **A "proves" line** — see below; this is what makes the scenario more than a smoke test.
3. **Environment preconditions** — what must already be true or already running before the
   scenario starts: services up, a specific record already existing, a specific config value
   set. Stated as a delta from a documented base environment, not re-derived per scenario.
4. **Numbered execution steps** — exact commands or actions, in order, with placeholders for
   any value the runner must resolve first (an id, a URL, a generated token).
5. **Pass/fail criteria, stated as a checklist** — each condition that must hold, phrased so it
   can be checked mechanically (a specific field equals a specific value, a specific log line
   appears, a count changes by exactly one) — never "looks right." **All listed conditions must
   hold, or the scenario fails**; a partial pass is not a pass.
6. **Cleanup** — how to return the environment to its prior state, or an explicit "none
   required" when the system's own lifecycle handles it (e.g. a background expiry process).

A scenario file groups scenarios that share one execution environment; a scenario needing a
genuinely different environment (a different topology, a second isolated account, a destructive
reset) gets its own file rather than being folded in.

### One-line skeleton

```
## S-<id> — <what this proves, in one line>            `<destiny tag>`

**Proves:** <design invariant or flow, with a pointer to the doc that states it>

### Preconditions (delta from base environment)
...

### Execute
1. <command/action>
2. <command/action>

### Verify — ALL must hold, else FAIL
1. <mechanically checkable condition>
2. <mechanically checkable condition>

### Cleanup
<exact steps, or "none required" with why>
```

---

## The "proves" linkage

Every scenario names **which design invariant or which end-to-end flow it proves**, with a
pointer to the doc that states that invariant (a component's `DESIGN.md`, or a shared flow doc).
This is what separates a runbook from an ad hoc manual test: a runbook exists *because* a design
document made a claim, and the scenario is the falsifiable check of that specific claim.

The link runs in one direction only — the design doc is the definition, the runbook is the
exercise. A runbook never introduces a new rule of its own; if running a scenario surfaces
behavior the design doc doesn't actually claim, that is a signal to go fix the design doc (or
the code), not to quietly encode a new expectation only in the runbook.

Practically, this means a scenario's "proves" line should be specific enough that deleting the
scenario would leave a named gap — "proves recovery after a mid-flight failure resumes from
durable state, per the component's `DESIGN.md`" is a real link; "proves the happy path works" is
not specific enough to justify the runbook's existence over an ordinary smoke test.

---

## Destiny tags

Every scenario carries a **destiny tag** — a stated answer to "what should eventually happen to
this scenario," so a runbook folder doesn't quietly become a permanent shadow test suite that
nobody planned to keep manual forever. Three destinies:

- **`permanent`** — this scenario exercises real behavior of a genuine external dependency (a
  live third-party service, a hardware interaction, a cross-account boundary) that an automated
  suite cannot run cheaply or faithfully. It stays a runbook indefinitely, run before a release
  or after a change to the infrastructure it touches.
- **`automate: <target>`** — this scenario is really testing something an automated test *could*
  cover once the right test harness exists (e.g. a self-contained integration suite for the
  component involved). It graduates to an automated test when that suite exists, and the runbook
  entry then shrinks to a pointer at the automated test, rather than staying a full duplicate
  procedure.
- **`retire`** — this scenario proved something during a specific investigation or a one-time
  migration and has no ongoing reason to be re-run; it is deleted once its purpose is served,
  not left to accumulate as dead weight.

A scenario with no destiny tag is an oversight, not a valid state — every scenario commits to
one of these three so the runbook folder has a known trajectory rather than only ever growing.

---

## Where runbooks sit relative to the Fact

Runbooks are not the Fact and do not define it. The Fact — the present-state truth of what a
component or the system currently is — lives in design docs and code (see
[`methodology.md`](./methodology.md)). A runbook **exercises** that truth from the outside: it
runs the real system and checks that observed behavior matches what the design doc already
claims. It is evidence *for* the Fact, never a second, competing source of it.

Concretely, this means:
- A runbook never states a rule the design doc doesn't already state — if a scenario's
  pass/fail criteria assert something novel, that assertion has to land in the design doc first
  (or be rejected there), and the runbook's "proves" line updated to point at it.
- A design doc never depends on a runbook to be readable — a person reading a component's
  `DESIGN.md` gets the whole invariant without needing to go check whether a runbook for it
  exists or currently passes.
- When a runbook and a design doc disagree, the design doc is not automatically right — but the
  disagreement is a signal to resolve explicitly (fix the code, fix the doc, or fix the
  scenario), never to let the runbook quietly encode the "real" behavior on the side.

This keeps runbooks in their proper role: a falsifiable, repeatable way of checking that the
present-state truth is actually true when run for real — never a shadow definition of it.

---

## See also

- [`testing.md`](./testing.md) — the three-checks discipline and design-derived automated
  tests; the tier a runbook scenario graduates into under an `automate:` destiny tag.
- [`design-docs.md`](./design-docs.md) — the invariants a runbook's "proves" line points at.
- [`the-loop.md`](./the-loop.md) — the worker/orchestrator loop that a runbook scenario
  ultimately verifies the output of.
