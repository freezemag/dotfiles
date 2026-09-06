#!/usr/bin/env bash
# Test for the post-push PR hold: a throwaway remote and clone, no network.
#   bash scripts/test-postpush-pr.sh   (exit 0 = all as expected)
set -e
D="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
git init -q --bare "$T/remote.git"
git clone -q "$T/remote.git" "$T/work" 2>/dev/null
cd "$T/work"
git config user.email t@example.com; git config user.name t
git checkout -q -b main
echo a > a; git add a; git commit -qm A; git push -q -u origin main
git remote set-head origin main
fail=0
check() { if [ "$2" = "$3" ]; then echo "ok    $1 (exit $3)"; else echo "FAIL  $1: expected exit $2, got $3"; cat "$T/err" 2>/dev/null; fail=1; fi; }
post() { printf '{"tool_input":{"command":"git push -u origin %s"}}' "$1" | CLAUDE_PROJECT_DIR="$PWD" bash "$D/postpush-pr.sh" 2>"$T/err"; echo $?; }
gate() { printf '{"tool_name":"%s","tool_input":{"command":"%s"}}' "$1" "$2" | CLAUDE_PROJECT_DIR="$PWD" bash "$D/pr-pending-gate.sh" 2>"$T/err"; echo $?; }
clear_() { printf '{"tool_name":"mcp__github__create_pull_request","tool_input":{}}' | CLAUDE_PROJECT_DIR="$PWD" bash "$D/pr-pending-clear.sh" 2>"$T/err"; echo $?; }

# 1. Push on the default branch: no hold.
echo b > b; git add b; git commit -qm B; git push -q origin main
check "push on main sets no hold" 0 "$(post main)"
[ ! -f .git/freezemag-pr-pending ] && echo "ok    no marker on main" || { echo "FAIL  marker on main"; fail=1; }

# 2. Push on a feature branch that landed: hold set, gate blocks.
git checkout -q -b feat; echo c > c; git add c; git commit -qm C; git push -q -u origin feat
check "push on feat sets the hold" 2 "$(post feat)"
grep -q "landed on 'feat'" "$T/err" && echo "ok    message names the branch" || { echo "FAIL  message"; fail=1; }
check "gate blocks an edit while held" 2 "$(gate Edit '')"
check "gate blocks a command while held" 2 "$(gate Bash 'git status')"
check "gate allows the deliberate override" 0 "$(gate Bash 'rm .git/freezemag-pr-pending  # PR 12 is open')"

# 3. Creating or subscribing to a PR clears the hold.
check "create_pull_request clears" 0 "$(clear_)"
[ ! -f .git/freezemag-pr-pending ] && echo "ok    marker removed" || { echo "FAIL  marker still there"; fail=1; }
check "gate open again" 0 "$(gate Bash 'git status')"

# 4. A push that did not land (still ahead of upstream): no hold.
echo d > d; git add d; git commit -qm D
check "failed push sets no hold" 0 "$(post feat)"

# 5. Not this project's push: skipped.
out="$(printf '{"tool_input":{"command":"cd /elsewhere && git push"}}' | CLAUDE_PROJECT_DIR="$PWD" bash "$D/postpush-pr.sh" 2>/dev/null; echo $?)"
check "push from another directory" 0 "$out"
exit $fail
