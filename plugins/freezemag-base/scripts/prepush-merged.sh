#!/usr/bin/env bash
# Runs before a `git push` Claude makes from the project directory. Refuses
# the push when the branch's PUSHED tip is already in the default branch:
# that means its pull request was merged, and every commit pushed after
# that lands on a branch no pull request covers. (atlas, 2026-09-04: the PR
# was merged eighteen minutes after it was opened; eight commits went to the
# same branch over the next four hours and were in nothing.) A merged PR is
# finished. The fix is stated in the block message: restart the branch from
# the default branch, keep its name, open a new draft PR.
#
# What it detects: a merge-commit merge (GitHub's default), because the
# pushed tip is then an ancestor of the default branch but not on its
# first-parent line. A branch pushed empty right after branching is on the
# first-parent line and is left alone. Squash and rebase merges make new
# commits, so the pushed tip is not an ancestor and they are NOT detected
# here; the rule in session-context.sh (read the PR's state before every
# push) covers those.
#
# Skipped, silently, when the push is not this project's (the command
# changes directory or uses `git -C`), when there is no origin, when the
# branch is the default branch or has never been pushed, or when the fetch
# fails (a guard that blocks on a network error would block every push on
# a bad connection). Set FREEZEMAG_SKIP_PREPUSH=1 to bypass once.
[ "${FREEZEMAG_SKIP_PREPUSH:-}" = "1" ] && exit 0
CMD="$(python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("command",""))' 2>/dev/null || cat)"
case "$CMD" in *"cd "*|*"git -C"*|*"--git-dir"*) exit 0;; esac
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
git remote | grep -qx origin || exit 0
BR="$(git branch --show-current)"
[ -n "$BR" ] || exit 0
DEF="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
if [ -z "$DEF" ]; then
  for c in main master; do
    git ls-remote --exit-code --heads origin "$c" >/dev/null 2>&1 && { DEF="$c"; break; }
  done
fi
[ -n "$DEF" ] || exit 0
[ "$BR" = "$DEF" ] && exit 0
# The branch's pushed tip, as the remote has it now; a branch never pushed
# has nothing to have been merged.
git ls-remote --exit-code --heads origin "$BR" >/dev/null 2>&1 || exit 0
git fetch -q origin "$DEF" "$BR" 2>/dev/null || exit 0
TIP="$(git rev-parse -q --verify "refs/remotes/origin/$BR" 2>/dev/null)" || exit 0
git rev-parse -q --verify "refs/remotes/origin/$DEF" >/dev/null 2>&1 || exit 0
# Nothing new to push past the default branch: nothing to protect.
[ "$(git rev-list --count "origin/$DEF..HEAD" 2>/dev/null || echo 0)" -gt 0 ] || exit 0
git merge-base --is-ancestor "$TIP" "origin/$DEF" 2>/dev/null || exit 0
# On the first-parent line of the default branch means the branch was pushed
# at a commit that IS the default branch's history (branched and pushed
# empty), not a merged side line.
if git rev-list --first-parent "origin/$DEF" 2>/dev/null | grep -qx "$TIP"; then exit 0; fi
{
  echo "freezemag guard: push blocked. The pushed tip of '$BR' ($(git rev-parse --short "$TIP")) is already in '$DEF': its pull request was merged, so anything pushed now lands on a branch no PR covers."
  echo "Restart the branch on the same name: git fetch origin $DEF && git rebase --onto origin/$DEF origin/$BR && git push --force-with-lease -u origin $BR, then open a NEW draft PR. Set FREEZEMAG_SKIP_PREPUSH=1 for a deliberate skip."
} >&2
exit 2
