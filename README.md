# DTDD

**Design-Test-Driven Development for AI coding agents — one component at a time, against its design.**

DTDD makes your repository maintain a single living **Fact** — the present-state truth of
what the system currently is — and makes every agent change either read that Fact or evolve
it deliberately, behind gates that block drift. The result: agents you can point at a
repo-wide change and trust, because what they read is re-checked at every commit by an
independent reviewer and what they write is verified before it lands. (The gate makes
*forgetting* the check impossible — its threat model is forgetfulness, not circumvention;
the stamp it consumes could be forged by an agent determined to cut corners, and the check
itself is a reviewer's judgment. The guide is explicit about which guarantees are
mechanical and which are discipline.)

## Why

AI coding agents are good at executing against context and bad at knowing which context is
true. The common answer — assemble good context per prompt: gather the right files, write a
careful brief — works exactly once. It has no maintenance story: nothing forces yesterday's
brief to still be true today, so by the hundredth change the agent is reading stale docs and
confidently building on them. Documentation that nothing enforces always rots; agents make
the rot expensive.

DTDD's answer is structural, not per-prompt. The design docs *are* the agent's working
substrate — read before every change, updated as the last step of every change, and guarded
by a commit gate that mechanically blocks code whose docs drifted. History is banished to
dedicated logs so the docs stay present-state. Every change runs design-first,
test-from-design, one component at a time, with a human holding the commit decision. What
you get back is compounding: the more changes land, the more enforced-true context exists
for the next one — instead of the usual decay.

The full argument, and the thirteen working ideologies behind it, are in
[guide/methodology.md](guide/methodology.md).

## What you get

Files on disk; load only when relevant.

- **A methodology guide** (`guide/`) — the Fact model and thirteen working ideologies, the
  8-step component worker loop, repo-wide orchestration with two human gates, the log
  discipline, review lenses, and the three-checks verification rule. Readable standalone;
  the plugin below is this guide made installable.
- **A conductor skill** (`skills/dtdd/`) — `/dtdd` drives one repo-wide change: seam-detect
  from design docs, plan wave (read-only) → your approval → execute wave → fan-in → your
  commit gate. It never commits; you do.
- **Two agents** (`agents/`) — `dtdd-component`, the per-component worker (bounded to a
  single component; its method forbids git — an instruction, not a physical restriction,
  and the guide is honest about which disciplines are gated vs instructed), and
  `design-sync`, the independent pre-commit reviewer that verifies every changed
  component's `DESIGN.md` still matches its code and stamps the commit gate.
- **A pre-commit hook** (`hooks/design-sync-gate.sh`) — a Claude Code `PreToolUse` gate
  (not a git hook) that blocks an agent session's `git commit` unless the design-sync stamp
  exists, and consumes the stamp on pass. Within agent-driven work — the flow DTDD governs —
  docs cannot silently drift from code.
- **A scaffolder** (`commands/dtdd-init.md`) — `/dtdd-init` sets up a target repo:
  doc skeletons for both Fact tiers, empty decision/improvement logs, and a methodology
  rules block proposed for your `CLAUDE.md`. Idempotent; never clobbers existing files.
- **Templates** (`templates/`) — the fixed 12-section component `DESIGN.md` template and
  the two log templates.
- **A worked example** (`examples/orderflow/`) — a docs-only skeleton of a fictional
  four-component repo with every DTDD artifact in its place; see the map below.

## Install

```
/plugin marketplace add ssdhage/dtdd
/plugin install dtdd
```

Then, in the repository you want to adopt DTDD:

```
/dtdd-init          # scaffold docs, logs, and CLAUDE.md rules (safe to re-run)
/dtdd <change>      # run a design-driven, repo-wide change
```

Your first `/dtdd` run pauses twice: once to show you the plan before anything is written,
once to show you the full diff and check results before you commit. Those two pauses are
permanent — commit authority never leaves the human.

## The map

Read in this order; each document is self-contained.

| Doc | What it carries |
|---|---|
| [guide/methodology.md](guide/methodology.md) | The Fact model + the thirteen ideologies — start here |
| [guide/the-loop.md](guide/the-loop.md) | The 8-step worker loop, orchestration waves, document ownership |
| [guide/design-docs.md](guide/design-docs.md) | Component `DESIGN.md` discipline + the 12-section template |
| [guide/repo-docs.md](guide/repo-docs.md) | The cross-component Fact tier + reading priority |
| [guide/the-logs.md](guide/the-logs.md) | Decisions-log vs improvements-log; ID and lifecycle discipline |
| [guide/review-gates.md](guide/review-gates.md) | Non-overlapping review lenses + the stamp/consume gate |
| [guide/testing.md](guide/testing.md) | Typecheck ≠ build ≠ run; design-derived tests |
| [guide/runbooks.md](guide/runbooks.md) | Executable scenarios: preconditions, steps, pass/fail, destiny |
| [guide/principal-orchestrator.md](guide/principal-orchestrator.md) | The top tier: spec-as-goal across stages (pattern documentation — the working skill ships in v2) |
| [guide/roadmap.md](guide/roadmap.md) | What v2 ships |

Then see all of it standing in one place: [examples/orderflow/README.md](examples/orderflow/README.md)
walks a fictional four-component repo with every document tier in position — the mental map,
the folder map, and a real seam traced across three documents. This is what a DTDD-adopted
repo looks like on disk:

```
examples/orderflow/                      ← a fictional web-shop checkout, docs-only skeleton
├── README.md                            ← the tour: mental map, folder map, reading order
├── CLAUDE.md                            ← the repo's agent rules (what /dtdd-init proposes)
├── docs/                                ← the Repo Fact + the logs beside it
│   ├── architecture/
│   │   ├── architecture.md              ← system flow, the two seam contracts, cross-cutting rules
│   │   └── data-model.md                ← the shared DB: 3 tables, one writer per table
│   ├── decisions/decisions-log.md       ← permanent: 3 decisions, incl. one dated superseding entry
│   ├── improvements/improvements-log.md ← transient: Next ID counter + 2 open entries
│   ├── runbooks/duplicate-charge.md     ← executable proof of a payments invariant + destiny tag
│   └── templates/DESIGN.template.md     ← where the 12-section template sits after /dtdd-init
├── apps/web/DESIGN.md                   ← the storefront (frontend) — Component Fact
└── services/
    ├── orders/DESIGN.md                 ← HTTP API; produces the charge-requested contract
    ├── payments/DESIGN.md               ← queue worker; consumes it, publishes charge-settled
    └── fulfillment/DESIGN.md            ← consumes charge-settled; owns shipments
```

(In a real repo each component folder also holds `src/`, `tests/`, and so on — omitted here
because the example teaches the documentation structure, not the code.)

## The cost, and what it buys

DTDD spends model invocations deliberately, and on design first. One `/dtdd` run dispatches
each candidate component's worker twice — but the two dispatches are different work, not the
same work repeated. The first is the read-only **plan wave**: the component validates the
change against its own design before a single line is written — what must be preserved, what
could go wrong, whether the proposed contract is even right. The second is the **execute
wave**: implementation against that validated, pinned design. Add the orchestrator holding
the run and the independent design-sync review before the commit, and a many-component
change is dozens of invocations.

That is the priority made explicit: **a validated design, then an implementation that lands
once** — instead of landing fast and paying the same tokens later as rework, review
findings, and regressions. The return compounds: every change leaves enforced-true context
for the next one. Still, spend it where it pays. Rules of thumb:

- **A change too small to survive the overhead doesn't need a run.** A one-line fix inside
  one component needs the worker discipline (design check, test, doc sync) — not the full
  orchestration. Use the loop's spirit; skip the fan-out.
- **Bad fits:** a prototype you'll discard, a repo without meaningful component boundaries
  (the model assumes components with their own design docs), a team that won't maintain the
  docs discipline — the gate only enforces what people actually write.
- **Good fits:** a long-lived multi-component repo where agents make changes at volume, and
  someone owns the methodology.
- **Portability:** the methodology (the guide) works with any agent harness; the shipped
  *enforcement* — hook, agents, skill — is Claude Code-specific.

## For agents

If you are an AI agent reading this repository: the methodology's rules for you are the
guide itself. Two of them govern everything else — read the relevant `DESIGN.md` before
touching a component, and never present work as done without the three checks (build,
tests, runtime smoke). The `/dtdd` skill encodes the full discipline; `guide/the-loop.md`
is your method.

## License

MIT — see [LICENSE](LICENSE).
