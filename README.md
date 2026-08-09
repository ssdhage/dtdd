# DTDD

**Design-Test-Driven Development for AI coding agents — one component at a time, against its design.**

AI agents are only as good as what they read. DTDD keeps a repository's design docs
permanently true: read before every change, updated as the last step of every change, and
checked by an independent reviewer before every commit. Agents work against docs they can
trust — and every change leaves better context for the next one.

## Why

Assembling good context per prompt works exactly once. Nothing keeps yesterday's brief true
today, so docs rot, and agents build confidently on stale truth. DTDD makes the docs
load-bearing instead: design first, tests derived from the design, code last, and a commit
gate that blocks when docs and code drift apart. History lives in two dedicated logs, so the
docs always describe the present.

**Why docs, not a memory layer or RAG?** Retrieval finds *similar* text, not *true* text —
a vector store happily serves the design from three commits ago, and nobody reviews an
embedding. Docs in the repo already have a truth-maintenance protocol: diffed in every PR,
gated at every commit, owned per component so an agent reads exactly its Fact. Memory and
RAG can sit on top — DTDD is what makes the thing they'd index worth retrieving.

The full argument, and the thirteen working ideas behind it:
[guide/methodology.md](guide/methodology.md).

## Who runs what

Three tiers, and the middle one is not you. **Your session becomes the Principal Orchestrator the moment
you type `/dtdd-goal <spec>`** — that invocation is the step that matters. The spec is
whatever settled what to build (a brainstorm, an RFC, a written plan); how it came to exist
doesn't matter to the machinery. From there the Principal decomposes the spec into stages and
drives `/dtdd` **once per implementation stage** (a doc-only stage runs a design pass
instead); each `/dtdd` run instantiates the orchestrator for that stage, and the
orchestrator's component agents do the implementing:

| Tier | Who it is | What it holds |
|---|---|---|
| **Principal** | Your session, from the moment it runs `/dtdd-goal <spec>` | The overall goal and its stages; absorbs routine stage-planning gates; re-scopes between stages from what actually landed |
| **Orchestrator** | Each `/dtdd` run — one per stage | That stage's plan and pinned contracts. It oversees: reads design docs, dispatches, fans in — it never writes component code |
| **Component agents** | `dtdd-component` workers — one per affected component | Implementation, inside their own component only, via the 8-step loop |
| **Reviewer** | The `design-sync` agent, fresh context before every commit | Docs↔code fidelity; creates the stamp the gate consumes |

**Design questions climb; nobody improvises.** A component agent that hits one *fails back*
— the **orchestrator answers first**, from the stage's plan and contracts. If the question
breaks the stage's assumptions, it **pops up to the Principal**, which answers from the
overall goal held in its context. Only a question that invalidates the goal itself reaches
you — plus the commit gate, which reaches you every time.

A whole goal, end to end. Note what you do and don't touch — after the one upfront
approval, only the commit gates come back to you:

```
you:       /dtdd-goal order cancellation, end to end — cancel from the page;
           payments must never charge a cancelled order

principal: goal restated; decomposed into 2 stages (backend endpoint + skip,
           then the cancel button against it). TOP-LEVEL GATE — approve?
you:       approve

principal: drives stage 1 via /dtdd; absorbs its planning gate (it holds the
           goal and did the decomposition)
  orchestrator: execute wave (producer first) — workers test-first, implement
     worker: failback — "skipped charges: publish a settled event, or stay silent?"
     orchestrator: answers from the stage plan (stay silent), re-dispatches
  orchestrator: fan-in — build, tests, boot; decisions-log entry; design-sync
                reviews docs↔code and stamps
principal: COMMIT GATE — diff + results + anything it adjudicated. Commit?
you:       commit        ← the gate consumes the stamp; stage 1 lands

principal: re-scopes stage 2 against what landed, drives it the same way
principal: COMMIT GATE — stage 2. Commit?
you:       commit        ← goal converged; summary of what each stage delivered
```

## What you get

- **The guide** (`guide/`) — the methodology in ten short chapters.
- **`/dtdd-goal`** (`commands/dtdd-goal.md`) — takes a whole spec, decomposes it into stages,
  drives `/dtdd` per implementation stage, and brings the human only the commit gates.
- **`/dtdd`** (`skills/dtdd/`) — one repo-wide change: plan → your approval → execute →
  review → your commit. It never commits; you decide.
- **Two agents** (`agents/`) — a per-component worker, and an independent reviewer that
  keeps every changed component's `DESIGN.md` matching its code.
- **A commit gate** (`hooks/`) — blocks an agent's commit until that review has run.
  Ships with its own test: `bash hooks/gate-test.sh`.
- **`/dtdd-init`** (`commands/`) — sets up any repo in one command. Never overwrites
  anything that already exists.
- **Templates** (`templates/`) — the 12-section component design doc and the two logs.
- **A worked example** (`examples/orderflow/`) — the whole structure in place; see the map.

## Install

```
/plugin marketplace add ssdhage/dtdd
/plugin install dtdd
```

Then, in the repo you want to adopt it:

```
/dtdd-init          # scaffold docs, logs, and CLAUDE.md rules (safe to re-run)
/dtdd <change>      # run a design-driven, repo-wide change
/dtdd-goal <spec>   # drive a whole multi-stage spec; /dtdd per stage
```

Every run pauses twice — once before anything is written, once before the commit. Those two
pauses are permanent: commit authority never leaves the human.

## The map

Read in this order; each chapter stands alone.

| Doc | What it carries |
|---|---|
| [guide/methodology.md](guide/methodology.md) | The core idea + the thirteen ideologies — start here |
| [guide/the-loop.md](guide/the-loop.md) | The 8-step worker loop and the orchestration around it |
| [guide/design-docs.md](guide/design-docs.md) | The component `DESIGN.md` discipline |
| [guide/repo-docs.md](guide/repo-docs.md) | The repo-wide docs: architecture, data model |
| [guide/the-logs.md](guide/the-logs.md) | The decisions log and the improvements log |
| [guide/review-gates.md](guide/review-gates.md) | Review lenses + the stamp/consume gate |
| [guide/testing.md](guide/testing.md) | Typecheck ≠ build ≠ run; tests derived from design |
| [guide/runbooks.md](guide/runbooks.md) | Executable scenarios with pass/fail criteria |
| [guide/principal-orchestrator.md](guide/principal-orchestrator.md) | The top tier — the pattern behind `/dtdd-goal` |
| [guide/roadmap.md](guide/roadmap.md) | What comes next |

Then see it all standing in one place — this is what a DTDD-adopted repo looks like on disk:

```
examples/orderflow/                      ← a fictional web-shop checkout, docs-only skeleton
├── README.md                            ← the tour: mental map, folder map, reading order
├── CLAUDE.md                            ← the repo's agent rules (what /dtdd-init proposes)
├── docs/
│   ├── architecture/
│   │   ├── architecture.md              ← system flow, the seam contracts
│   │   └── data-model.md                ← the shared DB: 3 tables, one writer per table
│   ├── decisions/decisions-log.md       ← permanent: why things are the way they are
│   ├── improvements/improvements-log.md ← transient: what's known-imperfect right now
│   ├── runbooks/duplicate-charge.md     ← executable proof of a critical invariant
│   └── templates/DESIGN.template.md     ← where the template sits after /dtdd-init
├── apps/web/DESIGN.md                   ← the storefront
└── services/
    ├── orders/DESIGN.md                 ← HTTP API; produces the charge-requested contract
    ├── payments/DESIGN.md               ← queue worker; consumes it, publishes charge-settled
    └── fulfillment/DESIGN.md            ← consumes charge-settled; owns shipments
```

(A real repo also has `src/` and `tests/` beside each `DESIGN.md` — omitted because the
example teaches the documentation structure, not the code.)

## The cost, and what it buys

Every component in a change is visited twice: once to **validate the design** (read-only —
what must be preserved, what could go wrong, is the contract right), once to **implement
against that validated design**. That's the deal: pay for the design up front, land the
implementation once, skip the rework. It adds up on big changes, so spend it where it pays:

- A one-line fix doesn't need the full run — use the loop's discipline, skip the fan-out.
- Bad fits: prototypes, repos without component boundaries, teams that won't maintain docs.
- Good fits: long-lived multi-component repos where agents change code at volume.
- The guide works with any agent harness; the shipped enforcement is Claude Code-specific.

One honest note: the gate guards against *forgetting* the review, not against an agent
determined to lie — the guide is explicit about which guarantees are mechanical and which
are discipline.

## For agents

Read the component's `DESIGN.md` before touching it. Never claim done without the three
checks: build, tests, runtime smoke. Your full method: [guide/the-loop.md](guide/the-loop.md).

## License

MIT — see [LICENSE](LICENSE).
