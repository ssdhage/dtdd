# The DTDD Methodology

*Design-Test-Driven Development for AI coding agents — one component at a time, against its design.*

This is the lead document of the guide. It explains the single idea everything else serves
— the Fact model — and the thirteen ideologies that follow from it. The other documents in
this folder each take one slice of the practice and go deep; this one gives you the frame
that makes them cohere.

---

## The problem

AI coding agents are good at executing against context and bad at knowing which context is
true. "Context engineering" answers this by assembling good context per prompt: gather the
right files, write a good brief, hand it over. That works once. It does not survive the
hundredth change, because hand-assembled context has no maintenance story — nothing forces
yesterday's brief to still be true today.

DTDD makes a stronger claim: **the repository maintains a single living Fact — the
present-state truth of what it currently is — and all work is either reading that Fact or
evolving it deliberately.** Context stops being something you assemble per request and
becomes a *maintained artifact* with strict rules about what belongs in it (present-state
facts) and what is tracked beside it (decisions, improvements, open questions).

Everything in this repository — the worker loop, the orchestration tiers, the gates, the
templates, the logs — exists to keep that Fact honest while agents change code at speed.

---

## The Fact model

The repo's Fact is **present-state truth = design docs + code**, held in two tiers:

- **Component Fact** — each component's `DESIGN.md`: its contract, mechanism, and
  invariants. One document per component, following one fixed template
  (see [design-docs.md](design-docs.md)).
- **Repo Fact** — the cross-component truth no single component's document can hold:
  architecture, data model, business flows, shared schemas
  (see [repo-docs.md](repo-docs.md)).

Both tiers are present-state. A change may move either or both. The methodology's job is to
keep both honest and to evolve them without corruption — which is exactly what the worker
loop's read-first/write-last discipline and the design-sync gate enforce
(see [the-loop.md](the-loop.md) and [review-gates.md](review-gates.md)).

Two properties make the Fact usable by agents:

1. **It is the substrate.** An agent working on a component reads that component's
   `DESIGN.md` before anything else; an orchestrator planning a repo-wide change reads
   design documents only, never code internals. Docs — not code — are the bounded context.
2. **It is load-bearing.** Because gates block commits whose docs drifted from their code,
   an agent can *trust* what it reads. A Fact nobody enforces is just documentation, and
   documentation rots.

---

## The thirteen ideologies

These are the meta-layer the whole practice teaches. Each is stated as mechanism → rule →
why; the linked documents carry the full treatment.

### 1. The Fact model

A living present-state truth; all work reads or evolves it. **Rule:** every task starts by
reading the relevant Fact tier and ends by leaving it true. **Why:** agents execute against
what they read; a maintained Fact makes what they read reliable.

### 2. Fact ≠ Narrative

Present-state documents (the Fact) are kept strictly separate from the logs (the narrative
of change). **Rule:** design docs never contain history — no changelog verbs, no dates, no
"previously" or "now supports"; the logs are the *only* place history lives
(see [the-logs.md](the-logs.md)). **Why:** this is what stops docs from rotting. A document
that accretes history stops describing the system and starts describing its own past.

### 3. Lifecycle-aware dependency direction

A permanent artifact never points at a transient one. **Rule:** the decisions-log never
cites an improvements-log entry; a `DESIGN.md` sentence must still read correctly if the
improvement it mentions is later deleted; no run IDs, seam IDs, or ticket IDs appear in
code or docs. **Why:** transient artifacts get deleted by design. Any permanent artifact
that leans on one is guaranteed to dangle.

### 4. Docs are the bounded context

Design documents — not code — are the agent's substrate and the seam-detection surface.
**Rule:** the orchestrator is *forbidden* from reading a component's internals; when it
needs to know something about a component, it asks that component's agent in plan mode.
**Why:** reading internals invites the orchestrator to plan against implementation details
that are free to change, and it silently bypasses the Fact — if the answer isn't in the
design doc, the correct move is to fix the design doc, not to peek.

### 5. Reasoning-actor ownership

Whoever does the reasoning at a tier writes that tier's document. **Rule:** a canonical doc
write is never delegated to a cheaper model; the worker that changed a component writes its
`DESIGN.md`, the orchestrator that reasoned about the cross-component change writes the
shared docs. **Why:** the writer of a canonical document needs the full reasoning in
context; a summarizer working from someone else's diff produces plausible text, not truth.

### 6. Gates as single-use stamps

"Prove the check ran" is enforced structurally, not by trust. **Rule:** an upstream process
creates a one-use token only it can create; a downstream hook consumes it on pass and blocks
without it (see [review-gates.md](review-gates.md)). **Why:** an instruction ("run the check
before committing") can be forgotten or faked; a consumed stamp cannot be reused, and a
missing stamp blocks mechanically.

### 7. Non-overlapping review lenses

Many narrow reviewers, each declaring what it does *not* check, beat one fuzzy reviewer.
**Rule:** every review lens states its scope and its explicit non-scope; lenses are composed,
not merged. **Why:** a reviewer asked to check everything checks nothing in particular —
and two overlapping reviewers each assume the other caught it.

### 8. Explicit absence

Absence is a statement, never an omission. **Rule:** non-applicable template sections say
`None — <reason>.`; a skipped test announces exactly what was not exercised; a rejected
design is recorded as rejected. **Why:** a blank is ambiguous — it reads as either
"not applicable" or "nobody looked." Making absence explicit removes the ambiguity that
agents (and humans) otherwise paper over.

### 9. Three distinct checks

Typecheck ≠ build ≠ run, and all three are named gates (see [testing.md](testing.md)).
**Rule:** a passing typecheck does not prove the build emits artifacts; a passing build does
not prove the entrypoint boots. Verification names all three. **Why:** each check catches a
failure class the previous one is structurally blind to; collapsing them into "it compiles"
is how "done" ships broken.

### 10. One reusable template grammar

A fixed section template is a grammar, not a one-off. **Rule:** the same structural shape
governs any new document type you add — fixed headings, fixed order, explicit-absence
sections — rather than a bespoke structure per document. **Why:** agents parse a known shape
reliably and humans diff a known shape cheaply; every new bespoke structure is a new parser
everyone must write.

### 11. Plan-then-execute with tier-aware gates

A read-only assessment wave auto-runs (it writes nothing); the writing wave runs only after
approval. **Rule:** routine planning is absorbed by the tier that owns the goal; only a
break in assumptions, decisions, or design escalates to a human; the commit gate is always
human. Workers *failback* with a suggested fix rather than improvise
(see [the-loop.md](the-loop.md) and [principal-orchestrator.md](principal-orchestrator.md)).
**Why:** pausing a human for routine plans trains them to rubber-stamp; never pausing them
surrenders the one decision that must stay human. Tier-aware gating spends human attention
only where it changes the outcome.

### 12. Independent-context verification

The checker must never be the author. **Rule:** the design-sync review runs in a separate
context from the session that authored the diff — always. **Why:** the authoring session is
biased toward its own work by construction; it reads its diff as what it meant, not as what
it says. A fresh context has no stake in the diff.

### 13. Self-similar orchestration

Conductors compose. **Rule:** each tier stays in its own loop, spawns the tier below, and
holds its own gates — `Principal : DTDD-runs :: DTDD : component-workers`. The same shape
recurs at three levels (see [principal-orchestrator.md](principal-orchestrator.md)).
**Why:** one orchestration grammar learned once applies at every scale; a bespoke control
scheme per tier multiplies the surface a human must audit.

---

## How the pieces map to the ideologies

| Piece | Carries |
|---|---|
| [the-loop.md](the-loop.md) — worker loop + orchestration | 1, 4, 5, 11 |
| [design-docs.md](design-docs.md) — component `DESIGN.md` discipline | 1, 2, 8, 10 |
| [repo-docs.md](repo-docs.md) — the Repo Fact tier | 1, 4, 5 |
| [the-logs.md](the-logs.md) — decisions-log vs improvements-log | 2, 3 |
| [review-gates.md](review-gates.md) — lenses + stamp/consume gate | 6, 7, 12 |
| [testing.md](testing.md) — three checks + design-derived tests | 8, 9 |
| [runbooks.md](runbooks.md) — executable scenarios | 8, 9 |
| [principal-orchestrator.md](principal-orchestrator.md) — the top tier | 11, 13 |

The plugin (skill, agents, hook, commands) is the same methodology made installable — see
the repository README for what ships and how to adopt it in one command.

---

## What DTDD is not

- **Not a prompt library.** The prompts exist, but they are the smallest part; the
  methodology is the maintained Fact and the gates around it.
- **Not a replacement for your agent harness.** It layers a discipline on top of whatever
  the harness already provides.
- **Not documentation-for-its-own-sake.** Every document here is load-bearing: something
  reads it (an agent), something enforces it (a gate), or something derives from it (tests).
  A document nothing consumes does not belong in the Fact.
- **Not itself a system of components.** This repository *is* the methodology — a guide plus a
  thin plugin — so it carries no `DESIGN.md`, no architecture doc, and no decisions or
  improvements logs of its own. Those artifacts belong to the repos that adopt DTDD, where
  there are real components with real designs to keep in sync.
