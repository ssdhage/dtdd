#!/bin/bash
# Self-test for design-sync-gate.sh. Run: bash hooks/gate-test.sh
# Exercises the gate's branches against scratch git repos in a temp dir:
# quote-aware command detection (a quoted "git commit" mention does not trip it;
# `git -C <dir> commit` / `git -c k=v commit` do), DTDD-adoption scoping,
# stamp block / pass / consume, and non-commit passthrough.
set -u
H="$(cd "$(dirname "$0")" && pwd)/design-sync-gate.sh"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

mkdir -p "$T/dtdd-repo/docs/templates" "$T/plain-repo"
git -C "$T/dtdd-repo" init -q
touch "$T/dtdd-repo/docs/templates/DESIGN.template.md"
git -C "$T/plain-repo" init -q

run() { printf '{"tool_input":{"command":"%s"}}' "$1" | CLAUDE_PROJECT_DIR="$2" bash "$H" >/dev/null 2>&1; echo "$?"; }

pass=0; fail=0
check() {
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "PASS  $1";
  else fail=$((fail+1)); echo "FAIL  $1 (expected $2, got $3)"; fi
}

check "quoted mention in a DTDD repo is allowed"          0 "$(run "echo '\''run git commit later'\''" "$T/dtdd-repo")"
check "git -C . commit without a stamp is blocked"        2 "$(run "git -C . commit -m hi" "$T/dtdd-repo")"
check "git commit in a non-DTDD repo is allowed (scope)"  0 "$(run "git commit -m hi" "$T/plain-repo")"
check "git commit without a stamp is blocked"             2 "$(run "git commit -m hi" "$T/dtdd-repo")"
touch "$T/dtdd-repo/.git/.design-sync-stamp"
check "git commit with a stamp is allowed"                0 "$(run "git commit -m hi" "$T/dtdd-repo")"
[ -f "$T/dtdd-repo/.git/.design-sync-stamp" ] && st=still-there || st=consumed
check "the stamp is consumed by the pass"                 consumed "$st"
check "compound command ending in commit is blocked"      2 "$(run "git status && git commit -m x" "$T/dtdd-repo")"
check "a non-git command is allowed"                      0 "$(run "ls -la" "$T/dtdd-repo")"
check "git -c k=v commit without a stamp is blocked"      2 "$(run "git -c user.name=x commit" "$T/dtdd-repo")"
check "a non-commit git command is allowed"               0 "$(run "git log --oneline" "$T/dtdd-repo")"

echo "----"
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
