# Review Gates

Reviewing a change is itself a design problem. One reviewer that tries to check everything
— doc fidelity, conventions, security, correctness — ends up checking all of them shallowly,
and nobody can tell what its silence actually means: did it check security and find nothing,
or did it just not get there? DTDD (Design-Test-Driven Development for AI coding agents —
one component at a time, against its design) answers with ideology 7: **many narrow lenses,
each declaring what it does *not* check**, over one fuzzy reviewer.

## Non-overlapping lenses

A lens is a reviewer scoped to one concern, with an explicit boundary on the other side.
Stated generically, a typical lens set looks like this:

- **A doc-fidelity lens** — does the component's design doc still match the code that's
  about to land? It does *not* check whether the code is idiomatic, secure, or bug-free —
  only whether the doc and the code agree.
- **A conventions lens** — does the change follow the repo's own documented conventions:
  naming, template structure, ID discipline, where things live, shared-code import
  discipline (shared code is consumed as a built package by name, never via deep
  relative-source imports into another package's internals), and artifact hygiene (no stale
  or per-package lockfiles where the workspace shares one, no committed build output)? It
  does *not* check business logic or security invariants — only "does this look like the
  rest of the repo."
- **A security lens** — does the change respect the security invariants the repo has
  already committed to in its own docs (credential handling, input validation, access
  checks)? It does *not* grade code quality or convention adherence — only the specific
  invariants that are documented.
- **A correctness lens** — does the logic do what it's supposed to do; are there bugs, edge
  cases, or regressions? It does *not* check conventions or doc fidelity.
- **A performance/efficiency lens** — does the change waste work (redundant calls, missing
  batching or pooling, pagination mistakes, hot-path allocations)? It does *not* judge
  correctness or style — only cost. Often scoped to one subsystem where cost concentrates
  (a network client, a query layer) rather than run repo-wide.

The declared "does *not* check" half of each lens is not a disclaimer, it's the mechanism.
Without it, two lenses either both skip a concern (a silent gap) or both claim it (wasted,
conflicting review). With it, the concerns tile the change exactly once each, and a reader
knows precisely which lens is responsible for catching a given class of problem.

Two output rules apply to every lens. **A lens reports; it does not fix** — applying a
finding is the author's (or orchestrator's) decision, made with context the lens doesn't
have. And **a lens never grades its own findings' severity — the caller decides**: the lens
knows one concern deeply but not the change's stakes, so it states what it found and lets
the tier that owns the change weigh it. The compulsory doc-fidelity lens is the stated
exception to the first rule: its gate-enforced role includes applying mechanical fixes (a
renamed field, a moved default) directly and distinguishing mechanical drift from genuine
design divergence, while every on-demand lens only reports.

## Compulsory vs on-demand

Not every lens runs with the same force. One lens — the doc-fidelity check — is **hook-gated
and compulsory**: nothing commits without it, because a design doc that silently drifts from
the code is exactly the failure the whole methodology exists to prevent (see
[methodology.md](methodology.md), the Fact model). The other lenses are **on-demand**:
not mechanically enforced on every commit, but expected at fixed points in the change's
lifecycle. The compulsory lens protects the one thing that must never rot silently; the
on-demand lenses are still expected, just via discipline rather than a blocking gate.

**When each lens runs.** The doc-fidelity lens runs **before every commit** (the hook makes
this non-optional). The conventions, security, correctness, and performance lenses run at
the **pull-request boundary** — twice: **before opening a PR** (the author's side — catch it
before a reviewer spends time on it) and **when reviewing an incoming PR** (the reviewer's
side — an independent context checking someone else's diff, which is the lens at full
strength). A conventions or correctness pass on every micro-commit is wasted force; skipping
it at the PR boundary is a silent gap. Fixed timing is what makes the discipline auditable:
"was this PR conformance-reviewed?" has a yes/no answer.

## Independent-context verification

Ideology 12: **the checker is never the author.** A session that just wrote a diff is
structurally biased toward it — it remembers its own intent, glosses over its own shortcuts,
and reads its own code more charitably than a stranger would. So the doc-fidelity check does
not run inline in the authoring session; it's dispatched as a **separate agent** with a fresh
context and no stake in the change. It reads the same staged diff a genuinely independent
reviewer would, because it has no memory of writing it.

The same discipline applies to the on-demand lenses, not just the compulsory one: a
conventions, security, correctness, or performance pass run *by the session that authored
the diff* inherits the author's bias just as surely. Dispatch each as a fresh-context agent
— the gate only enforces this for doc-fidelity, but the reason holds for every lens.

The shipped example of this is [`../agents/design-sync.md`](../agents/design-sync.md): a
model-pinned, tool-restricted agent dispatched fresh for every commit. It reads the staged
diff, brings each affected component's design doc back in line with the code, and — this
matters as much as the fidelity check itself — refuses to silently paper over a genuine
divergence between what the doc says and what the code now does. A mechanical drift (a
renamed field, a moved file) it fixes directly; a real disagreement (the code now
contradicts a documented rule) it surfaces instead of resolving on its own authority, because
resolving it either way is a judgment call that belongs to a human, not to whichever session
happens to be running.

## The stamp/consume gate pattern

Ideology 6: a gate has to *prove* the check ran, not just assume it did — "the reviewer
usually remembers to run this" is not a gate, it's a hope. The pattern that makes the proof
structural:

1. **An upstream process creates a single-use stamp, and only it may create the stamp.** The
   review agent writes a stamp file as the very last step of a clean run — after every doc
   is verified or fixed, never before.
2. **A downstream hook consumes the stamp on pass.** It checks for the stamp's existence; if
   present, it deletes it (consuming it) and lets the action through. The deletion is the
   point — a stamp is good for exactly one pass, so the next commit can't coast on an old
   check.
3. **Absent stamp blocks, with instructions.** If the hook finds no stamp, it fails the
   action and prints exactly what to run to produce one. It never falls back to "proceed
   anyway" — an absent stamp means the check didn't happen, full stop. (The one exception is
   the script's own internal tooling failures — an unavailable interpreter, an unresolvable
   git directory — which fail open with a warning, so a broken hook cannot silently block
   every commit in the repo.)
4. **Nobody hand-creates the stamp.** Manually touching the stamp file defeats the entire
   pattern — it's indistinguishable, from the gate's point of view, from a real pass. The
   discipline only holds if the stamp's only legitimate origin is the review agent finishing
   its work. Stated plainly: this rule is itself unenforced — nothing mechanically stops a
   session from forging the stamp. The gate's threat model is *forgetfulness* (the common
   failure), not *circumvention* (which no file-existence check can stop); a session that
   would forge a stamp would also lie in a report, and no gate fixes that.
5. **A stamp goes stale the moment anything edits after it.** The stamp certifies the tree
   *as the review agent saw it*. Any write between stamp creation and the commit — a
   simplify pass, an applied review finding, a last manual tweak — invalidates that
   guarantee even though the file still exists: re-run the review agent (which re-stamps)
   after any post-stamp edit. For the same reason, **write-capable review passes run
   sequentially, never in parallel** — two passes editing the same files clobber each other,
   and the doc-fidelity check must always see the *final* state, so it runs last.

**Honesty note on point 5, prompt-enforced not gate-enforced.** What the hook mechanically
checks is stamp *presence* and consume-on-pass. Staleness is not detected: a stamp created
before a later edit still admits the commit, so re-running the review after any post-stamp
edit is discipline, not a gate. A future hardening would compare the stamp's timestamp
against later modifications and reject a stamp older than the tree it certifies.

One more limit worth naming plainly: the stamp proves the check *ran*, not that its judgment
was *right*. The reviewing agent is a model reading a diff; the gate makes skipping the
review impossible, not misjudging it. That is still the correct trade — an always-run
independent review catches what an occasionally-run perfect one misses — but "gated" here
means "cannot be skipped," never "cannot be wrong."

The shipped example is [`../hooks/design-sync-gate.sh`](../hooks/design-sync-gate.sh): a
pre-commit gate that looks for the stamp the doc-fidelity agent creates, consumes it on a
successful commit attempt, and blocks with the exact dispatch instructions if it's missing.
The same gate script can also carry a purely mechanical check that doesn't need a stamp at
all — for example, confirming that deleting an entry from the transient improvements-log
(see [the-logs.md](the-logs.md)) didn't leave a dangling reference elsewhere in the repo.
That check is deterministic and requires no judgment, so it runs unconditionally on every
commit attempt rather than waiting on the stamp.

## Why this composes with the rest of the methodology

The stamp pattern is what makes independent-context verification more than a suggestion —
without a structural gate, "dispatch a separate agent for this" is just another prose
instruction a busy session can skip under deadline pressure. And the non-overlapping lens
design is what keeps that one compulsory gate narrow: it only has to guarantee doc-fidelity,
because the other lenses cover the rest of the surface on their own schedule.

- [methodology.md](methodology.md) — ideologies 6, 7, and 12 stated in one line each.
- [the-loop.md](the-loop.md) — the worker loop's step 6 (finalize the design doc) is what the
  doc-fidelity lens is verifying; step 8 (three checks) is a different, non-overlapping
  concern (build/test/run, not doc↔code fidelity).
- [design-docs.md](design-docs.md) — the present-state and explicit-absence rules the
  doc-fidelity lens enforces when it edits a design doc.
- [the-logs.md](the-logs.md) — the dangling-reference sweep the mechanical (non-stamped) part
  of the gate performs.
