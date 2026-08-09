# Roadmap

What ships now, what's designed but deferred, and one possible future hardening. See
[`methodology.md`](./methodology.md) for the ideologies and [`the-loop.md`](./the-loop.md) for the
worker and orchestration tiers this roadmap builds on.

## v1 — the methodology and plugin, complete

Everything below ships and is usable today:

- The full guide: the Fact model, the thirteen ideologies, the worker loop, orchestration,
  document ownership, review gates, and the testing discipline.
- The installable plugin: the conductor skill, the design-sync agent, the component-worker agent,
  the pre-commit gate hook, and the scaffold command that installs the methodology into a target
  repo.
- The three-tier orchestration model in full — including the top tier, the Principal Orchestrator
  — documented as a *pattern* in [`principal-orchestrator.md`](./principal-orchestrator.md): what
  it does, why it must be the session and not a spawned agent, its five responsibilities, and the
  tier-aware gate model spanning all three tiers.

v1 is complete and self-contained without the item below — a team can adopt the methodology and
run DTDD (Design-Test-Driven Development for AI coding agents — one component at a time,
against its design) stages by hand, one at a time, driving the top tier's discipline
themselves without a dedicated skill for it.

## v2 — the Principal Orchestrator as a working skill

The one piece of the top tier not yet shipped as an artifact: a skill that runs the
`principal-orchestrator.md` pattern mechanically — reading a spec, decomposing it into stages,
driving each stage's engine, adjudicating the gate model, and re-scoping as stages land — instead
of a session performing that loop by hand.

This is deliberately held back rather than shipped alongside v1. It is the one genuinely new
artifact in the whole export — everything else here is a proven pattern already exercised across
real work before being written down — so it is built and run against real, multi-stage goals
first, in a private setting, until its rough edges (how it phrases a re-scope, how it presents a
correctable-vs-goal-invalidating break) are shaken out. Only then is it genericized — stripped of
anything specific to where it was built — and ported into this plugin as `/dtdd-goal`. The concept
is already fully documented in `principal-orchestrator.md`; v2 turns that documented pattern into
a runnable artifact, unchanged in shape.

## Possible future hardenings

Two gaps are recorded here for the same honesty reason: each is a place where the
methodology's claim is currently held by discipline rather than by a gate. (The gate script
itself ships with a runnable self-test — `hooks/gate-test.sh` — covering its blocking,
scoping, and stamp-consumption branches.)

**Stamp staleness detection.** The pre-commit gate checks that the design-sync stamp
*exists* and consumes it; it does not detect an edit made after the stamp was created (see
the honesty note in [`review-gates.md`](./review-gates.md)). A hardening would compare the
stamp's timestamp against later modifications and reject a stamp older than the tree it
certifies.

### A gated red-state proof

The worker loop's two halves are currently enforced asymmetrically. The **Design** half is
gate-enforced: a pre-commit hook blocks the commit unless the design-sync stamp exists, and that
stamp can only be created by the independent design-sync check. The **TDD** half is
prompt-enforced only: a worker is instructed to write tests first and confirm they fail for the
right reason before writing implementation code, but nothing mechanically captures that red state
happened. A compliant worker does real red-first TDD; nothing currently stops a worker from
writing tests after the fact and simply asserting that red occurred.

A future hardening would close this gap the same way the design half is already closed: capture a
red-state proof (for example, a recorded test-run result showing failure) before implementation
is allowed to proceed, and gate on that proof the same way the pre-commit hook gates on the
design-sync stamp. This is not designed or scheduled yet — it is recorded here as the honest gap
between what DTDD claims (real TDD) and what v1 can currently prove mechanically.
