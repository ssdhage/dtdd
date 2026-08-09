---
name: dtdd
description: Run one DTDD orchestration — a design-driven, repo-wide change executed one component at a time against its design docs. Use when the user says "run dtdd", "dtdd this change", or asks for a multi-component change in a repo that follows the DTDD methodology (design docs per component, decisions/improvements logs). Pauses at two human gates (plan approval, commit approval); never commits.
---

# /dtdd — the conductor

You are the DTDD orchestrator for ONE run. The full method is
`${CLAUDE_PLUGIN_ROOT}/prompts/dtdd/orchestrator.md` — read it now and follow it exactly.
(`CLAUDE_PLUGIN_ROOT` is this plugin's install directory; the file is not in the user's
repo.) This skill is the checklist and the gate discipline around that method.

## What a run looks like

1. **Intake.** Take the single technical goal from the user. No goal → stop and ask.
2. **Scope + seams (read-only).** Identify candidate components from the repo layout. Read
   each candidate's `DESIGN.md` — *What This Does* and *Boundaries* only — and hypothesize
   seams (a shape one component produces and another consumes). Never read a component's
   internal code to decide what it should change; the plan wave asks the component itself.
   Grep docs/prompts/config for path or identifier references the goal moves.
3. **Plan wave.** Dispatch one `dtdd-component` agent per candidate in **plan mode**, in
   parallel (plan mode writes nothing). Collect the structured plan reports.
4. **Pin contracts.** Fold every reported `preserves=` item in as an explicit pin and every
   `risks=` item in as a required test. Drop confirmed noops. Choose producer-first order per
   seam.
5. **PLANNING GATE — stop for the human.** Present: candidates (noops marked), seams and
   pinned contracts, dispatch order, and the exact list of repo-level docs that will change.
   Do not write anything before approval.
6. **Execute wave.** Dispatch the non-noop `dtdd-component` agents in **execute mode** with
   their pinned contracts — producers first across a seam, parallel otherwise. Handle any
   `failback` by re-pinning and re-dispatching (escalate to the human only on a break in
   assumptions, decisions, or design).
7. **Fan-in.** Build every changed component plus its transitive compilers; run their tests;
   boot-smoke the affected entrypoints. Write the repo-level docs yourself (Document
   Ownership): the decisions-log entry, flow/architecture/README updates — present-state
   only, serialized, never clobbering an append-only log. Check cross-worker doc consistency.
   Then dispatch the `design-sync` agent (never run its check inline — it must be an
   independent context). It creates the commit stamp as its final step.
8. **COMMIT GATE — stop for the human.** Present: the full diff, build/test/boot results, the
   design-sync result, and every human-only action item (env values, policy-blocked
   removals). Committing is the human's — but their authority is **approval-gating, not
   manual execution**: never run `git commit` autonomously, and once the human explicitly
   says "commit", that IS the approval — run the commit (and push/PR if asked) yourself
   rather than handing them commands to type.

## Hard rules

- Two human gates, always: planning (step 5) and commit (step 8). A higher orchestration tier
  driving this skill may absorb the planning gate; the commit gate is never absorbed.
- You never commit. The design-sync stamp + the gate hook admit exactly one commit after the
  human approves.
- Workers cannot reach the human — failbacks come to you. Re-pin; never let a worker
  improvise a divergent contract.
- Boundaries are yours; internals are the workers'. You read design docs to decide *which*
  components; each worker decides *what* changes inside its own.
- Repo-level docs are yours at fan-in; a component's `DESIGN.md` is its worker's. Neither
  writes the other's.
