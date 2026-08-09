# Testing

DTDD (Design-Test-Driven Development for AI coding agents — one component at a time, against
its design) treats tests as a **derivative of the design**, not an afterthought bolted on
after the code works. This document covers three things: the three checks a component must pass before
it is "done," how tests are derived from a design doc rather than invented, and the honest
limit of what the methodology can currently enforce mechanically versus what it only asks for.

See [`the-loop.md`](./the-loop.md) for where these checks sit inside the worker's eight steps,
and [`design-docs.md`](./design-docs.md) for the invariants and contracts that tests are
derived from.

---

## Three distinct checks: typecheck ≠ build ≠ run

A green typecheck, a green build, and a working runtime are three different claims. Conflating
any two of them is how "all checks passed" ships something that doesn't actually work.

1. **Typecheck** — the compiler or linter confirms the code is internally type-consistent.
   This is the cheapest and weakest check: it never touches the module resolver's real output
   path, never emits a file, never loads a real config value.
2. **Build** — the component's real build step (the one a deploy would run) actually emits
   artifacts: compiled files, a bundle, generated code. This is a stronger and different check
   than typechecking — a no-emit typecheck can pass while the real build fails on a path
   alias, a circular import, or a project-reference boundary that only the emit step resolves.
   A build must run the real build command, not a `--no-emit`/`--check`-only variant of it.
3. **Run** — the changed entrypoint or runtime surface is actually started (or invoked) with a
   minimal valid input, and observed to behave. This is the only one of the three that catches
   a runtime-only failure: a config value read from an environment variable that isn't set the
   way the build assumed, a file path that resolves correctly at compile time but not when the
   process actually boots, a dependency that resolves in source but not from the built output.

**Mechanism → rule → why:** each check exercises a strictly larger slice of reality than the
one before it — types, then emitted artifacts, then a live process — and each slice can fail
independently of the others. → The rule is that all three are named, separately reported gates;
none may stand in for another. → The reason is structural, not pedantic: "it typechecks" is a
claim about syntax, "it builds" is a claim about assembly, and "it runs" is the only claim about
behavior. A team that stops at typecheck or build and calls the component done is asserting
something it never actually checked. **"Builds" is not "runs."**

A worker (or a human, working manually) reports each of the three as its own line — build:
pass/fail, test: pass/fail (see below), and a runtime smoke: pass/fail — rather than a single
rolled-up "checks passed."

---

## Design-derived tests

Tests in DTDD are not invented by guessing what might break; they are **derived from the
design doc's stated invariants and any pinned contract** (the frozen shape a component exposes
to, or consumes from, another component — see [`the-loop.md`](./the-loop.md) for seam
detection).

The rule: **every invariant the design doc states, and every field/shape in a pinned contract,
becomes at least one test case.** If a design doc says "a request missing the required
identifier is rejected before any side effect," that sentence is not decoration — it names a
test that must exist. If a contract pins a field as non-nullable, a test asserts that a
consumer breaks visibly (not silently) if the field arrives null.

Each test follows **Arrange / Act / Assert**, with the three sections marked explicitly as
comments even where the rest of the codebase keeps comments minimal — test structure is the one
place a repo's brevity convention makes a deliberate exception, because the three-part shape is
what makes a test readable as a claim rather than a script.

**Red before green.** A test derived from an invariant is run *before* the implementing code
changes, and must fail — and fail *for the stated reason*, not for an unrelated error (a typo in
the test itself, a missing import). Confirming the right kind of failure is what proves the test
is actually exercising the invariant, rather than trivially passing regardless of the code under
test. Only once that red is observed does implementation proceed to make it green.

This is genuine red-green-refactor test-driven development — the derivation step (from design,
not from imagination) is what DTDD adds on top of plain TDD.

---

## Test tiers

Not every test can run everywhere, and pretending otherwise is how a passing test suite quietly
depends on infrastructure that may not exist in the environment running it. DTDD separates tests
into three tiers by **what environment they require**, independent of any specific tool choice:

| Tier | What it exercises | Needs external infrastructure? | Runs by default in an automated pass? |
|---|---|---|---|
| **Unit** | One function or unit, pure logic | No | Yes |
| **Self-contained integration** | Multiple units wired together, or a real engine, but only in-process/embedded dependencies (no live external service) | No | Yes |
| **Infra-gated** | A real external dependency — a live network service, a running server process, a real managed datastore | Yes | No — opt-in only, and its absence must be stated |

A concrete illustration of the middle tier: a component that needs "real SQL through a real
data-access layer" can often get that from an **embedded, in-process database engine** rather
than a live database server — giving integration-level fidelity with none of the infrastructure
dependency. (An in-process test runner, an embedded database engine, and a similar embedded
message-queue emulator are examples of tools that make this tier possible — the tier is the
rule; any specific tool is just today's implementation of it.)

**Mechanism → rule → why:** a test tier is decided by its infrastructure requirement, not by
what it happens to be testing. → Unit and self-contained integration tests must run with zero
network access and zero external services, full stop; the moment a test needs a live dependency
it is no longer either of those tiers. → If that boundary is blurred, a worker's "tests pass"
silently depends on infrastructure that may be absent in the environment that ran it, and a
green report stops meaning anything reliable.

---

## The skip-contract naming rule

An infra-gated test is legitimate — some behavior genuinely can only be verified against a real
external dependency — but it must never disappear silently. This is the same discipline as
"explicit absence" applied to tests specifically: **a skipped test announces exactly what was
not exercised.**

The rule has two parts:
1. **Naming makes the gate visible.** An infra-gated test is named or grouped so that any runner
   can identify and exclude it *by rule*, not by someone remembering to comment it out. A test
   that reaches a live external dependency is never indistinguishable, by name or location, from
   a self-contained test.
2. **A skip is reported, never implied.** Any run that excludes infra-gated tests states which
   ones it skipped and why (missing environment, not part of this pass) — it does not present a
   green result as if it were full coverage. "Passed" and "passed, minus these named exclusions"
   are different claims, and only the second one is honest when exclusions exist.

Silence is the failure mode this guards against: a report that says "tests pass" while quietly
omitting an entire tier reads as full confidence to anyone who didn't write it. Naming the
absence turns an omission into a statement.

---

## The honesty note: prompt-enforced, not gate-enforced

DTDD is candid about an asymmetry between its two halves, rather than overclaiming the
methodology's own name.

The **Design** half — validating a component's design doc before any code, and finalizing that
doc only after the change lands — is **gate-enforced**: a structural check (an independent
review pass, run in a separate context from the one that authored the change) stamps the work
as design-synced, and a commit is mechanically blocked without that stamp. Nothing gets through
without the check actually having run.

The **TDD** half is **prompt-enforced**: the worker is instructed to write tests first and to
confirm a red failure before implementing, and a compliant worker genuinely does that. But no
machinery captures proof that red was observed before green — there is no mechanical artifact
equivalent to the design-sync stamp for the test-first sequence. A worker that writes the
implementation first and the tests after, then reports "red confirmed," cannot currently be
caught by anything but a human or reviewer noticing.

This gap is named deliberately rather than glossed over: a future hardening — capturing an
actual red-state result before green is allowed to proceed — would close it. Until that exists,
the discipline is real and expected, but it rests on the worker following instructions, not on a
gate that blocks the alternative.

---

## See also

- [`the-loop.md`](./the-loop.md) — where the three checks and test-writing sit inside the eight
  worker steps.
- [`design-docs.md`](./design-docs.md) — the invariants and contracts tests are derived from.
- [`runbooks.md`](./runbooks.md) — executable scenarios that exercise a design's behavior at a
  coarser grain than a unit test, including ones destined to become automated tests later.
- [`review-gates.md`](./review-gates.md) — the stamp/consume gate pattern behind the design-sync
  enforcement described above.
