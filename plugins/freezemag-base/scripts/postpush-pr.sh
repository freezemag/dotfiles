#!/usr/bin/env bash
# Runs after a `git push` Claude makes from the project directory. If the
# push landed on a branch other than the default branch, it drops a marker
# in .git and tells Claude that no further work happens until a pull
# request covers the branch. The marker is cleared by pr-pending-clear.sh
# when Claude creates a PR or subscribes to one (the GitHub tools), and
# enforced by pr-pending-gate.sh, which blocks Edit, Write and Bash while it
# exists. (smarthome, 2026-09-05 and 06: four commits pushed to a branch
# whose PR had been closed; nothing asked whether a PR still covered it.)
#
# Why a marker and not a GitHub query: hooks in cloud sessions cannot reach
# the GitHub API (403), so the guard works from what the session does.
#
# Skipped when the push is not this project's (cd or git -C in the command),
# when the push did not land (still ahead of upstream), or on the default
# branch. Set FREEZEMAG_SKIP_PREPUSH=1 to bypass once.
[ "${FREEZEMAG_SKIP_PREPUSH:-}" = "1" ] && exit 0
CMD="$(python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("command",""))' 2>/dev/null || cat)"
case "$CMD" in *"cd "*|*"git -C"*|*"--git-dir"*) exit 0;; esac
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" || exit 0
GITDIR="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
BR="$(git branch --show-current)"
[ -n "$BR" ] || exit 0
DEF="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
[ -z "$DEF" ] && for c in main master; do git show-ref -q --verify "refs/remotes/origin/$c" && { DEF="$c"; break; }; done
[ "$BR" = "$DEF" ] && exit 0
# Did the push land? Ahead of upstream by zero means yes.
UP="$(git rev-parse -q --verify '@{u}' 2>/dev/null)" || exit 0
[ "$(git rev-list --count "$UP..HEAD" 2>/dev/null || echo 1)" -eq 0 ] || exit 0
printf '%s\n' "$BR" > "$GITDIR/freezemag-pr-pending"
{
  echo "freezemag guard: the push landed on '$BR'. Nothing else happens until a pull request covers it."
  echo "Now: list the repository's open pull requests for head '$BR'. If one is open, subscribe to it (subscribe_pr_activity). If none is open, create a draft PR against '${DEF:-main}' and subscribe to it. Either tool clears this hold."
  echo "A closed or merged PR does not count. If the branch's PR was merged, restart the branch from '${DEF:-main}' first (see the prepush-merged guard)."
} >&2
exit 2
