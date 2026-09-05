#!/usr/bin/env bash
# The prepush-merged guard's own test: a throwaway remote and clone, no
# network. Three pushes it must allow and one it must block.
#   bash scripts/test-prepush-merged.sh   (exit 0 = all four as expected)
set -e
G="$(cd "$(dirname "$0")" && pwd)/prepush-merged.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
git init -q --bare "$T/remote.git"
git clone -q "$T/remote.git" "$T/work" 2>/dev/null
cd "$T/work"
git config user.email t@example.com; git config user.name t
git checkout -q -b main
echo a > a; git add a; git commit -qm A; git push -q -u origin main
git remote set-head origin main
run() { printf '{"tool_input":{"command":"git push -u origin %s"}}' "$1" | CLAUDE_PROJECT_DIR="$PWD" bash "$G" 2>"$T/err"; echo $?; }
fail=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then echo "ok    $1 (exit $3)"; else echo "FAIL  $1: expected exit $2, got $3"; cat "$T/err"; fail=1; fi; }

# 1. A branch with unmerged pushed commits: allowed.
git checkout -q -b feat; echo b > b; git add b; git commit -qm B; git push -q -u origin feat
echo c > c; git add c; git commit -qm C
check "unmerged branch, pushing more" 0 "$(run feat)"

# 2. The branch's pushed tip merged into main with a merge commit: blocked.
git checkout -q main; git merge -q --no-ff -m "merge feat" origin/feat; git push -q origin main
git checkout -q feat
check "merged branch, pushing more" 2 "$(run feat)"
grep -q "already in 'main'" "$T/err" && echo "ok    the block names the default branch" || { echo "FAIL  block message"; fail=1; }

# 3. A branch pushed empty at main's tip, then given commits: allowed.
git checkout -q main; git pull -q origin main; git checkout -q -b fresh; git push -q -u origin fresh
echo d > d; git add d; git commit -qm D
check "branch pushed empty from main, then commits" 0 "$(run fresh)"

# 4. A push that is not this project's (cd in the command): skipped.
out="$(printf '{"tool_input":{"command":"cd /elsewhere && git push"}}' | CLAUDE_PROJECT_DIR="$PWD" bash "$G" 2>/dev/null; echo $?)"
check "push from another directory" 0 "$out"

exit $fail
