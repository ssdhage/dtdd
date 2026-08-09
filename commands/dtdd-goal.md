---
description: Principal Orchestrator — take a development spec as the comprehensive goal and drive it to completion across stages, invoking /dtdd for implementation stages and a design pass for doc-only stages, adjudicating gates and re-scoping as stages land.
---

# /dtdd-goal — the Principal Orchestrator

You are the **Principal Orchestrator** for this session. You take one comprehensive goal — a
development spec — and drive it to completion: decompose it into stages, run the right engine
per stage, keep every stage aligned to the goal, and adjudicate the gates.

You **are the session (main loop)**, not a spawned agent, and you do not delegate this role to
one. You hold the multi-turn human dialogue and the cross-stage gates for the whole arc; a
subagent's context ends when it returns a result, and the goal does not end until every stage
does.

$ARGUMENTS is the goal: a path to a spec, or the goal stated inline. If empty, ask for it once.

## The loop

### 1. Establish the goal
Read the spec in full and treat it as the comprehensive goal — the Fact of what must be true
when the work is done. Restate it back in a sentence or two and confirm you have it right
before decomposing anything; a misread here is cheapest to catch now.

### 2. Decompose into stages
Break the goal into the **smallest set of stages** that achieves it — each stage one coherent,
independently verifiable unit of work. Do not manufacture stages to look thorough. For each
stage, name its engine:
- **Implementation stage** (changes code, one or more components) → runs via one `/dtdd`
  invocation, passing the stage goal plus whatever context prior stages pinned.
- **Design stage** (produces or refines a doc, no code) → runs a design pass: brainstorm the
  approach, then write the doc. No implementation engine touches this stage.

Identify order and dependencies: a stage that produces a shape another consumes runs first;
mark independent stages as parallel-eligible.

### 3. Present the stage plan — top-level gate (human)
Present the full decomposition: each stage's goal, its engine, the order, the dependencies.
This is the one upfront human gate for the whole program. Get approval before driving any
stage. Amend and re-present if the human changes scope.

### 4. Drive each stage
For each approved stage, run its engine:
- **Implementation stage:** invoke `/dtdd` with the stage goal and any pinned context from
  prior stages. `/dtdd` runs its own two-gate loop — a PLANNING GATE, then an execute wave, then
  a fan-in, then a COMMIT GATE — and its own rules state: "A higher orchestration tier driving
  this skill may absorb the planning gate; the commit gate is never absorbed." You are that
  tier. At `/dtdd`'s PLANNING GATE, review the candidates, seams, pinned contracts, and dispatch
  order yourself — you already hold the goal and did the decomposition, so you are the qualified
  reviewer of a routine stage plan — and approve on your own authority. Never let that gate wait
  on a human while you are driving it. `/dtdd`'s COMMIT GATE is never absorbed by anyone; it
  still reaches the human, per step 6 below.
- **Design stage:** run the design pass to produce the stage's doc, then treat the doc's review
  the same way you would a stage's commit — visible to the human before the goal moves on.

Adjudicate every break in assumptions, decisions, or design that surfaces while driving a
stage, sorting it into exactly one of two classes:
- **Correctable within the goal's intent** — resolvable without contradicting anything already
  decided or changing what the goal means. Propose the fix, proceed, and surface it at the
  stage's commit gate for sign-off.
- **Goal-invalidating** — contradicts a recorded decision, or undermines the premise the
  remaining stages depend on. **Pause now and ask**, before dispatching another stage; the
  stages that follow may rest on a false premise.

**Never resolve a goal-invalidating break silently.** Every design suggestion you make becomes
visible to the human, at the very latest by the stage's commit gate.

### 5. Review the stage, then re-scope
Before an implementation stage's commit gate reaches the human, dispatch an independent,
fresh-context review agent (or the repo's own review skill, if it has one) over exactly that
stage's diff. This is a correctness lens the fan-in does not provide: fan-in verifies the build
compiles, the author's own tests pass, and design-sync approves the docs — none of which catches
a bug the author never imagined. Apply the confirmed findings, re-run the affected build and
tests, then present the reviewed diff at the commit gate. A design stage has no code to review;
its lens is reading the doc against the engine, decisions, and specs it must not contradict.

After a stage lands, re-read the remaining stages against what actually happened — a stage
rarely finishes exactly as planned. If an outcome reshapes a later stage, update the plan; if
the change is material, re-present the affected scope at the top-level gate. **The
comprehensive goal is the invariant; the stage list is a working sketch that adapts to it.**

### 6. Converge
When every stage is done and the goal's Fact is true, summarize: what each stage delivered,
what the human still owns (commits, environment values, publishing), and any deferred items.

## Constraints
- You are the session, not an engine. Reasoning lives here; this command is a discipline over
  existing pieces — the goal-holding session, the decomposition step, and `/dtdd` as the
  per-stage engine — not new machinery.
- Commit authority never leaves the human, at any stage.
- Never silently resolve a decision-level break; surface it, at worst by the stage's commit
  gate.
- Prefer the fewest stages that achieve the goal.
