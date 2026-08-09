# The Principal Orchestrator (Top Tier)

DTDD — *Design-Test-Driven Development for AI coding agents, one component at a time, against
its design* — is a three-tier orchestration model. This document covers the top tier: the
**Principal Orchestrator**, the layer that turns a development spec into a finished, multi-stage
piece of work. The two tiers below it — the DTDD orchestrator (one change) and the component
worker (one component) — are covered in [`the-loop.md`](./the-loop.md); the ideologies that motivate
all three tiers are covered in [`methodology.md`](./methodology.md).

## What it is

A development spec — a design doc, an RFC, a written plan — describes something bigger than one
DTDD run can finish in a single pass: it spans multiple components, multiple kinds of work
(some of it code, some of it design), and multiple points where a human needs to look at what
landed before more work continues. The Principal Orchestrator is the tier that holds that whole
arc.

**Mechanism.** The Principal Orchestrator is not a spawned agent — it **is the session itself**,
running as a thin skill (conventionally invoked as `/dtdd-goal <spec>`) over the main loop. It
reads a spec, treats it as the comprehensive goal (the Fact of what must be true when the work is
done), and drives that goal to completion by running the DTDD loop underneath it, stage by stage.

**Rule: never a spawned agent.** The Principal Orchestrator must be the session, not a subagent
dispatched by one. It holds two things a subagent structurally cannot: the multi-turn human
dialogue that spans the whole arc, and the cross-stage gates that depend on everything decided so
far. A subagent's context ends when it returns a result; the Principal's does not end until the
goal does.

**Why.** Splitting "decompose and hold the goal" into a subagent would sever the one thread that
makes adaptive alignment possible — the running memory of what was decided, what landed, and what
must still hold true. A goal that spans stages needs a single continuous holder of that context,
and only the session itself stays alive across every stage boundary and every human turn.

## The five responsibilities

The Principal Orchestrator's loop has five steps. It is a discipline over existing pieces — the
session holding the goal, the plan/decompose step, and DTDD as the per-stage engine — not a new
engine of its own.

1. **Read the spec as the goal.** Read the development spec in full and treat it as the
   comprehensive goal — the Fact of what must be true when the work is done. Restate it back in a
   sentence or two before proceeding, so a misread surfaces before any stage is planned.
2. **Decompose into DTDD-sized stages.** Break the goal into the smallest set of stages that
   achieves it, where each stage is one coherent, independently verifiable unit — sized so a
   single DTDD run (for code) or a single design pass (for a doc-only stage) can finish it.
   Manufacturing extra stages just to look thorough works against the goal: the invariant is the
   comprehensive goal, not stage count.
3. **Drive the loop, per stage.** For each stage in order, run the right engine: an
   implementation stage (it changes code) runs the DTDD orchestration loop below this tier; a
   design-only stage (it produces or refines a doc, no code) runs a design pass instead. The
   Principal supplies the stage goal and whatever was pinned by prior stages, then waits for the
   engine's result.
4. **Adjudicate the gates.** Apply the tier-aware gate model (below) at every stage boundary:
   absorb the routine planning decision itself, and escalate to the human only when a stage's
   plan or outcome breaks an assumption, a recorded decision, or the design.
5. **Re-scope from what landed.** After a stage lands, re-read the remaining stages against what
   actually happened — a stage rarely finishes exactly as planned. If an outcome reshapes a later
   stage, update the plan; if the change is material, re-present the affected scope. The
   comprehensive goal is the invariant; the stage list is a working sketch that adapts to it.

What distinguishes this from "run the DTDD loop N times in sequence" is step 5: each stage's
outcome re-informs the next, rather than the whole decomposition being fixed and blind at the
start.

## Self-similar orchestration

The same shape recurs at every tier, one level down each time:

> **Principal Orchestrator : DTDD runs :: DTDD orchestrator : component workers**

The Principal decomposes a goal into DTDD runs and spawns them one stage at a time, exactly as
the DTDD orchestrator decomposes a change into per-component work and spawns a worker per
component. Each tier stays in its own loop, spawns only the tier directly below it, and holds
its own gates — it does not reach two levels down, and it does not do the tier below's reasoning
for it. A Principal Orchestrator does not inspect a component's code any more than a DTDD
orchestrator does; both work from the declared surface the tier below reports back, not from
peeking inside it.

This is why the model composes cleanly as the work grows: adding a tier never means inventing a
new coordination pattern, only applying the one pattern one level higher.

## The tier-aware gate model

Three gates exist across the three tiers. Each is handled by the tier that owns the reasoning
behind it — only a genuine divergence climbs to the level above.

| Gate | Tier | Handled by | Human pause? |
|---|---|---|---|
| Component fail-back | 3 (component worker) | reported up to the DTDD orchestrator | never |
| Planning gate | 2 (DTDD orchestrator, per stage) | absorbed by the Principal Orchestrator | only on a break in assumptions / decisions / design |
| Commit gate | 1 (Principal Orchestrator → human) | the human, at each stage boundary | **always** |

**A component's fail-back never pauses a human.** A worker that finds the assigned contract wrong,
or the goal incompatible with a standing invariant, reports `failback` with a suggested fix to the
DTDD orchestrator — it does not, and structurally cannot, reach the human directly. The
orchestrator re-pins and re-dispatches. This keeps a single component's local uncertainty from
interrupting a session-level dialogue over something the orchestrator can resolve on its own.

**The per-stage planning gate is absorbed by the Principal**, not bounced to the human by default.
The Principal already holds the comprehensive goal and performed the decomposition — it is the
qualified reviewer of a routine stage plan, the same way the DTDD orchestrator is the qualified
reviewer of a routine component plan one tier down. Escalating every stage plan to the human would
turn a multi-stage goal into a wall of low-value approvals; the Principal only escalates when a
stage's plan or outcome represents a genuine break in assumptions, decisions, or design — not
routine execution detail.

**The commit gate is always human**, with no exception at any tier. This is the backstop that
makes absorbing the planning gate safe: whatever the Principal decided or provisionally proceeded
on is still reviewed, in full, before anything is committed. Delegating the planning gate only
works because the stronger gate — commit — never moves.

## The two escalation classes

When the Principal's absorbed planning judgment hits a break in assumptions, decisions, or design,
it sorts the break into exactly one of two classes:

- **Correctable within the goal's intent.** The break can be resolved without contradicting
  anything already decided or changing what the goal means. The Principal proposes the fix,
  proceeds provisionally, and surfaces the proposal visibly at the next commit gate for human
  sign-off. Stages are not blocked on something the Principal is confident it read correctly.
- **Goal-invalidating.** The break contradicts a recorded decision, or undermines the premise the
  remaining stages depend on. The Principal **pauses now** and asks, before dispatching another
  stage — proceeding would risk building further stages on a premise that no longer holds.

**Never silent.** Every design suggestion the Principal makes during this adjudication becomes
visible to the human, at the very latest by the next commit gate. A decision-level contradiction
is never resolved silently and folded into the diff unannounced — silence at this tier is exactly
the failure mode the gate model exists to prevent, because a silently-resolved contradiction can
propagate through every stage that follows before anyone notices.

## Status

**This tier ships as a working command.** `/dtdd-goal <spec>` (`commands/dtdd-goal.md`) runs the
pattern documented above: it reads the spec as the goal, decomposes it into stages, drives each
implementation stage through one `/dtdd` invocation — absorbing its planning gate per the
tier-aware gate model — dispatches an independent review over each stage's diff before its commit
gate, and re-scopes between stages as they land. The commit gate still always reaches the human.
