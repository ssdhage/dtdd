#!/bin/bash
# PreToolUse gate (Claude Code hook, NOT a git hook): before a `git commit`
# Bash call in a DTDD-adopted repo, require a design-md sync for that commit.
#   - Scope: active only in repos that adopted DTDD, detected by the scaffold
#     marker docs/templates/DESIGN.template.md (created by /dtdd-init). In any
#     other repo the gate exits silently — installing the plugin does not gate
#     the rest of the machine.
#   - Command detection is quote-aware (shlex), not a text match: a quoted
#     mention of "git commit" inside another command does not trip the gate;
#     `git -C <dir> commit` and `git -c k=v commit` do trip it.
#   - Stamp file: <git-dir>/.design-sync-stamp, created by the design-sync
#     agent's last step (agents/design-sync.md). Consume-on-pass: the gate
#     deletes the stamp as it lets ONE commit through — one check, one commit.
#   - No stamp → exit 2 (blocks the tool call; stderr is shown to the model,
#     which dispatches the design-sync agent and retries the commit).
#   - Internal errors fail OPEN (warn, allow); a genuinely absent stamp fails
#     CLOSED (block).

input=$(cat)

if ! command -v python3 >/dev/null 2>&1; then
  echo "design-sync-gate: python3 not found; cannot parse hook input — allowing commit (fail-open)." >&2
  exit 0
fi

is_commit=$(printf '%s' "$input" | python3 -c '
import json, shlex, sys

try:
    cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")
    tokens = shlex.split(cmd)
except Exception:
    print("no"); sys.exit(0)

SEPARATORS = {"&&", "||", ";", "|", "&"}
ARG_FLAGS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}

segments, current = [], []
for tok in tokens:
    if tok in SEPARATORS:
        segments.append(current); current = []
    else:
        current.append(tok)
segments.append(current)

def is_git_commit(seg):
    if not seg or seg[0].split("/")[-1] != "git":
        return False
    i = 1
    while i < len(seg):
        tok = seg[i]
        if tok in ARG_FLAGS:
            i += 2                      # flag takes a separate argument
        elif tok.startswith("-"):
            i += 1                      # attached-value or bare flag
        else:
            return tok == "commit"      # first subcommand decides
    return False

print("yes" if any(is_git_commit(s) for s in segments) else "no")
' 2>/dev/null)

[ "$is_commit" = "yes" ] || exit 0

repo_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Scope: only gate repos that adopted DTDD (the /dtdd-init scaffold marker).
[ -f "$repo_root/docs/templates/DESIGN.template.md" ] || exit 0

# Resolve the actual git dir: in a normal checkout this is <repo>/.git; in a linked
# worktree, .git is a pointer file and the real dir lives under the main checkout.
gitdir=$(git -C "$repo_root" rev-parse --absolute-git-dir 2>/dev/null)
if [ -z "$gitdir" ]; then
  echo "design-sync-gate: could not resolve git dir; allowing commit (fail-open)." >&2
  exit 0
fi
stamp="$gitdir/.design-sync-stamp"

# Mechanical check (runs regardless of the stamp): the improvements-log is transient, so an
# IMP-XXX entry deleted from it must not leave dangling references elsewhere in the staged
# tree. Log path is configurable; the check is skipped silently if the repo has no log.
log="${DTDD_IMPROVEMENTS_LOG:-docs/improvements/improvements-log.md}"
if [ -f "$repo_root/$log" ]; then
  removed=$(git -C "$repo_root" diff --cached -- "$log" 2>/dev/null | grep -oE '^-### IMP-[0-9]+' | grep -oE 'IMP-[0-9]+' | sort -u)
  if [ -n "$removed" ]; then
    added=$(git -C "$repo_root" diff --cached -- "$log" 2>/dev/null | grep -oE '^\+### IMP-[0-9]+' | grep -oE 'IMP-[0-9]+' | sort -u)
    deleted=$(comm -23 <(printf '%s\n' "$removed") <(printf '%s\n' "$added"))   # removed and NOT re-added (ignores rewordings)
    dangling=""
    for imp in $deleted; do
      hits=$(git -C "$repo_root" grep --cached -l -e "$imp" -- . ":(exclude)$log" 2>/dev/null)
      [ -n "$hits" ] && dangling="$dangling\n  $imp still referenced in:\n$(printf '%s\n' "$hits" | sed 's/^/    /')"
    done
    if [ -n "$dangling" ]; then
      printf 'Design-sync gate: an improvements-log entry was deleted but is still referenced.\n' >&2
      printf 'The improvements-log is transient — remove/update these references (or restore the entry) before committing:%b\n' "$dangling" >&2
      exit 2
    fi
  fi
fi

if [ -f "$stamp" ]; then
  rm -f "$stamp"    # consume: this pass is spent; the next commit needs a fresh check
  exit 0
fi

cat >&2 <<'MSG'
Design-MD sync gate: no design-sync stamp found for this commit.
Before committing, dispatch the design-sync agent (Agent tool, subagent_type: design-sync)
— an independent context, never the session that authored the diff. It verifies each staged
component's DESIGN.md still matches the staged code (12-section template at
docs/templates/DESIGN.template.md), updates mechanical drift, STOPs and surfaces design
divergences, creates a template-based DESIGN.md for any new component, and creates the stamp
itself as its final step. Do NOT touch the .design-sync-stamp file by hand — let the agent
create it. Then retry the commit. The stamp is single-use — consumed by the commit it admits.
MSG
exit 2
