# <Component Name> — Design & Decision Log

> This is the canonical template for every component's `DESIGN.md` in this repository.
> All twelve sections appear in every `DESIGN.md`, in this order, even when not
> applicable — a non-applicable section keeps its heading with a one-line
> `None — <reason>.` body, so readers always find the same structure and an empty
> section is a visible statement, not an omission.
>
> **Writing standard (applies to every section):** the document must be self-contained.
> Explain what a mechanism IS and how it works *before* stating rules about it, then
> give the reason (the failure the rule prevents): mechanism → rule → why. No
> compressed jargon without its underlying explanation. The test: a reader with no
> prior context — human or LLM — should reconstruct an accurate picture from this file
> alone. The code is the source of truth for *what happens*; this file records what
> must remain true, why, and what was rejected.
>
> **Present-state only:** describe the current design as if it always was. Do not use
> changelog verbs — `replaced`, `removed`, `no longer`, `previously`, `formerly`,
> `used to`, `transitional`, `migrated from`, `deprecated`, `was X now Y` — do not
> date entries, and **do not define the present by the absence of the removed past**
> (no "no longer needs X", "no X needed", "not read from Y", "instead of the old Z").
> State the mechanism in the present tense: not "the service **is replaced by** a
> queue-based worker" but "the service processes work items via a queue-based worker."
> The before→after record — what changed, when, and why it moved — lives in
> `docs/decisions/decisions-log.md`, never here; only the logs
> (`decisions-log.md`, `improvements-log.md`) narrate change over time. Rejected
> *alternatives* are still in scope as present rationale ("we do X, not Y, because…")
> — that is the current design's reasoning, not its history.
>
> **No durable dependence on transient logs:** a doc may *point* to an `IMP-XXX`
> improvements-log entry, but must not *depend* on it — state the limitation
> self-contained in the present, so the sentence still reads correctly if that entry is
> later deleted (entries leave the improvements-log when resolved or rejected).
>
> **Current facts, not provenance:** never name the tool, command, or run that produced
> a change, and never link to a transient spec, plan, or discussion doc — state the
> fact. The decisions-log records *that* a decision was made; a doc whose subject *is*
> a tool (e.g. an orchestration design) may describe that tool, but a service or
> schema doc never cites the tool that produced its contents.

---

## 1. Header preamble

(Not a heading in the real file — this is the unnamed block under the H1 title.)
One paragraph: package or module name, what the component is in one sentence, where
to start reading the code (entry-point files in order), and pointers to any document
that must be read first.

## Why This Exists

The problem this component solves — what breaks, is impossible, or falls through the
cracks without it. State it in the present (the need that exists today), not as a
migration story; if this component took over from an earlier approach, that history
lives in the decisions-log, not here.

## What This Does

Responsibilities and contracts: inputs (message shapes, request bodies, function
arguments), outputs (responses, artefacts, rows, events), and the public API or
endpoint table. Reference material (endpoint tables, type shapes, file layouts)
belongs here.

## How It Works

The mechanism walkthrough a newcomer reads first: a numbered flow from trigger to
completion. Sub-mechanisms (concurrency model, retry model, evaluation semantics, …)
are subsections here.

A Mermaid `flowchart` may lead this section when the flow has branches a numbered list
can't show at a glance (failure/recovery paths, multi-step convergence). Keep node
labels short — the *why* stays in the prose; the diagram shows shape. Use the shared
palette so diagrams read consistently on a dark editor theme: stores (queues, object
storage, databases) as `classDef store fill:#1e3a5f,stroke:#5b9bd5,color:#fff;`, a
process/entry root as `classDef proc fill:#2d5a3d,stroke:#7bc47f,color:#fff;`, and
ordinary steps/decisions in the default node style. Always render every data store (DB
included) as a `store` node so "where the write lands" is explicit. Quote any label
containing `@` (e.g. `["@scope/package-name"]`) — Mermaid parses a bare `@` as special
node/edge syntax and errors otherwise.

## Boundaries

What each internal layer owns and what it must NOT know about (the testability
contract). Who consumes this component, what it depends on, and which identities/
credentials it runs under.

## Rules & Invariants

Everything that must remain true, each written as mechanism → rule → why. Ordering
rules, conflict rules, idempotency guarantees, delivery contracts, naming conventions.
This is the section reviewers check a change against.

## Key Design Decisions

Numbered. Each: the decision (stated in the present — what the design *is*), the
rationale, and the alternative that lost (one line is enough if obvious). No dates and
no "was X now Y" — the dated before→after record lives in the decisions-log; here each
entry reads as the current design and why it is so.

## Deliberately Left Out

What was considered and NOT built, with the reason — protects future readers from
re-proposing rejected designs. `None — nothing rejected yet.` if so.

## Configuration

Environment variables and tunable values: name, purpose, default, where it comes from
(`.env`, `.env.local`, deploy script). `None — no runtime configuration.` if so.

## Open Questions

Unsettled items only — anything listed here is acknowledged as undecided. Settled
questions move to Key Design Decisions. `None — no open questions.` if so.

## Next Steps

Ordered, near-term work for this component. `None — no near-term work planned.` if so.

## Related Documents

Pointers to the architecture doc, schema doc, sibling `DESIGN.md`s, runbooks, and the
decisions log — with one phrase saying what each contains.
