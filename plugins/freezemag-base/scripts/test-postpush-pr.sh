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
ok() { echo "ok    $1"; }
no() { echo "FAIL  $1"; fail=1; }
post() { printf '{"tool_input":{"command":"git push -u origin %s"}}' "$1" | CLAUDE_PROJECT_DIR="$PWD" bash "$D/postpush-pr.sh" 2>"$T/err"; echo $?; }
# A command that is not a push at all. The hook's own `if` filter is
# best-effort and documented to run the hook anyway on $(), backticks or a
# variable, so this is what actually reaches the script in a real session.
leak() { printf '{"tool_input":{"command":"for d in $(ls); do echo $d; done"}}' | CLAUDE_PROJECT_DIR="$PWD" bash "$D/postpush-pr.sh" 2>"$T/err"; echo $?; }
gate() { printf '{"tool_name":"%s","tool_input":{"command":"%s"}}' "$1" "$2" | CLAUDE_PROJECT_DIR="$PWD" bash "$D/pr-pending-gate.sh" 2>"$T/err"; echo $?; }
clear_() { printf '{"tool_name":"mcp__github__create_pull_request","tool_input":{}}' | CLAUDE_PROJECT_DIR="$PWD" bash "$D/pr-pending-clear.sh" 2>"$T/err"; echo $?; }

# 1. Push on the default branch: no hold.
echo b > b; git add b; git commit -qm B; git push -q origin main
check "push on main sets no hold" 0 "$(post main)"
[ ! -f .git/freezemag-pr-pending ] && ok "no marker on main" || no "marker on main"

# 2. Push on a feature branch that landed: hold set, gate blocks.
git checkout -q -b feat; echo c > c; git add c; git commit -qm C; git push -q -u origin feat
check "push on feat sets the hold" 2 "$(post feat)"
grep -q "landed on 'feat'" "$T/err" && ok "message names the branch" || no "message"
check "gate blocks an edit while held" 2 "$(gate Edit '')"
check "gate blocks a command while held" 2 "$(gate Bash 'git status')"

# 3. The escape hatch is Cem's environment variable, not deleting the marker.
#    (2026-09-11: the old message advertised `rm`, and a subagent did it.)
check "gate no longer exempts a command that names the marker" 2 \
  "$(gate Bash 'rm .git/freezemag-pr-pending  # PR 12 is open')"
out="$(printf '{"tool_name":"Bash","tool_input":{"command":"git status"}}' |
  FREEZEMAG_SKIP_PREPUSH=1 CLAUDE_PROJECT_DIR="$PWD" bash "$D/pr-pending-gate.sh" 2>"$T/err"; echo $?)"
check "gate honours FREEZEMAG_SKIP_PREPUSH" 0 "$out"

# 4. Creating or subscribing to a PR clears the hold and records the tip.
check "create_pull_request clears" 0 "$(clear_)"
[ ! -f .git/freezemag-pr-pending ] && ok "marker removed" || no "marker still there"
[ "$(cat .git/freezemag-pr-cleared)" = "$(git rev-parse HEAD)" ] &&
  ok "the cleared tip is recorded" || no "no cleared tip recorded"
check "gate open again" 0 "$(gate Bash 'git status')"

# 5. THE REGRESSION. An ordinary read-only command, after the hold was
#    cleared, must not put it back. Every Bash call in the smarthome session
#    of 2026-09-11 re-armed the hold this way.
check "a non-push command does not re-arm a cleared hold" 0 "$(leak)"
[ ! -f .git/freezemag-pr-pending ] && ok "still no marker after a leaked command" ||
  no "a leaked command re-armed the hold"

# 6. A stale push does not arm it either: same tip, but the push was long ago.
rm -f .git/freezemag-pr-cleared
python3 - <<'PY'
import re, time, pathlib
p = pathlib.Path(".git/logs/refs/remotes/origin/feat")
lines = p.read_text().splitlines()
lines[-1] = re.sub(r" (\d{10}) ", " %d " % (int(time.time()) - 1000), lines[-1], count=1)
p.write_text("\n".join(lines) + "\n")
PY
check "a push older than five minutes does not arm the hold" 0 "$(leak)"
[ ! -f .git/freezemag-pr-pending ] && ok "no marker for a stale push" || no "stale push armed it"

# 7. A reflog whose last entry is not a push does not arm it.
python3 - <<'PY'
import pathlib
p = pathlib.Path(".git/logs/refs/remotes/origin/feat")
lines = p.read_text().splitlines()
lines[-1] = lines[-1].replace("update by push", "fetch origin")
p.write_text("\n".join(lines) + "\n")
PY
check "a non-push reflog entry does not arm the hold" 0 "$(leak)"
[ ! -f .git/freezemag-pr-pending ] && ok "no marker without a push entry" || no "armed without a push"

# 8. A real push still arms it, reflog and all.
echo c2 > c2; git add c2; git commit -qm C2; git push -q origin feat
check "a fresh push arms the hold again" 2 "$(post feat)"
[ -f .git/freezemag-pr-pending ] && ok "marker present after a real push" || no "no marker after a real push"

# 9. Once the work is merged, the hold releases itself. A merged PR cannot be
#    subscribed to, so without this the session has no way out (2026-09-11).
git checkout -q main; git merge -q --no-ff -m "merge feat" feat; git push -q origin main
git checkout -q feat
check "gate releases once the tip is in main" 0 "$(gate Bash 'git status')"
[ ! -f .git/freezemag-pr-pending ] && ok "marker cleared by the merge" || no "marker survived the merge"

# 10. The clear hook is wired to the tools that actually exist. The matcher is
#     a string in hooks.json that no shell test touches, and the old value was
#     a list of exact names, so a second MCP server's tool could never match.
python3 - "$D/../hooks/hooks.json" <<'PY'
import json, re, sys
hooks = json.load(open(sys.argv[1]))["hooks"]["PostToolUse"]
entry = [h for h in hooks
         if any("pr-pending-clear" in x.get("command", "") for x in h["hooks"])]
assert len(entry) == 1, "expected exactly one pr-pending-clear entry"
m = entry[0].get("matcher", "")
# The documented rule: only letters, digits, _, -, spaces, commas and pipes
# means a list of exact strings; anything else is an unanchored regex.
plain = re.fullmatch(r"[A-Za-z0-9_\- ,|]*", m) is not None
def matches(tool):
    if m in ("", "*"):
        return True
    if plain:
        return tool in [p.strip() for p in re.split(r"[|,]", m)]
    return re.search(m, tool) is not None
bad = [t for t in ("mcp__github__create_pull_request",
                   "mcp__github__subscribe_pr_activity",
                   "mcp__Claude_Code_Remote__subscribe_pr_activity")
       if not matches(t)]
if bad:
    print("FAIL  matcher %r does not match: %s" % (m, ", ".join(bad)))
    sys.exit(1)
if matches("Bash") or matches("mcp__github__merge_pull_request"):
    print("FAIL  matcher %r is too broad" % m)
    sys.exit(1)
print("ok    the clear matcher covers every server that offers those tools")
PY
[ $? -eq 0 ] || fail=1

# 11. A push that did not land (still ahead of upstream): no hold.
rm -f .git/freezemag-pr-pending .git/freezemag-pr-cleared
echo d > d; git add d; git commit -qm D
check "failed push sets no hold" 0 "$(post feat)"

# 12. Not this project's push: skipped.
out="$(printf '{"tool_input":{"command":"cd /elsewhere && git push"}}' | CLAUDE_PROJECT_DIR="$PWD" bash "$D/postpush-pr.sh" 2>/dev/null; echo $?)"
check "push from another directory" 0 "$out"
exit $fail
