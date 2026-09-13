#!/usr/bin/env bash
# PreToolUse for Edit, Write, MultiEdit and Bash. While .git/freezemag-pr-pending
# exists (written by postpush-pr.sh), every edit and command is refused
# until a pull request covers the pushed branch. pr-pending-clear.sh removes
# the marker when Claude creates a PR or subscribes to one.
#
# Two ways out, and deleting the marker is not one of them. Until 2026-09-11
# this script printed "to lift it deliberately: rm <marker>" and exempted any
# command mentioning the marker by name, which taught the session, and a
# subagent of it, to delete the guard rather than satisfy it.
#
#   1. Create or subscribe to a pull request. That is the intended path.
#   2. FREEZEMAG_SKIP_PREPUSH=1 in the environment, which Cem sets and a
#      session cannot write for itself. The sibling guards honour the same
#      variable.
#
# The hold also releases itself once the work is merged: a tip that is already
# in the default branch was demonstrably covered by a pull request, and a
# merged PR can no longer be subscribed to, so holding on would leave the
# session with no way out at all.
[ "${FREEZEMAG_SKIP_PREPUSH:-}" = "1" ] && exit 0
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" 2>/dev/null || exit 0
GITDIR="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
F="$GITDIR/freezemag-pr-pending"
[ -f "$F" ] || exit 0
DEF="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
[ -z "$DEF" ] && for c in main master; do git show-ref -q --verify "refs/remotes/origin/$c" && { DEF="$c"; break; }; done
if [ -n "$DEF" ] && git merge-base --is-ancestor HEAD "refs/remotes/origin/$DEF" 2>/dev/null; then
  rm -f "$F"
  exit 0
fi
BR="$(cat "$F")"
{
  echo "freezemag guard: held. '$BR' was pushed and no pull request has been confirmed for it since."
  echo "Create a draft PR for '$BR' (create_pull_request) or subscribe to its open PR (subscribe_pr_activity). That clears the hold."
  echo "A closed or merged PR does not count. If the branch's PR was merged, the hold releases itself once this tip is in '${DEF:-main}'; restart the branch from '${DEF:-main}' (see the prepush-merged guard)."
} >&2
exit 2
