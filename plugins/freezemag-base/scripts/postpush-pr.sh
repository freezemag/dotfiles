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
# Why the push is proved from git rather than from the command text: this
# hook's `if` filter is documented best-effort. The hooks reference's Bash
# matching table gives `if: Bash(git push *)` against `echo $(date)` as
# "yes, runs" -- "patterns that specify more than the command name run the
# hook anyway on $(), backticks, or $VAR" -- and adds "Because the `if`
# filter is best-effort, use the permission system rather than a hook to
# enforce a hard allow or deny". So the hook fires on ordinary commands, and
# an ahead-of-upstream count of zero is true of every command on a branch
# that is in sync. Both together armed the hold after read-only commands all
# through the smarthome session of 2026-09-11. A push, by contrast, always
# writes an "update by push" entry on the remote-tracking ref, and that is
# what this script now requires.
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
# Did the push land? Ahead of upstream by zero is necessary, not sufficient.
UP="$(git rev-parse -q --verify '@{u}' 2>/dev/null)" || exit 0
[ "$(git rev-list --count "$UP..HEAD" 2>/dev/null || echo 1)" -eq 0 ] || exit 0
HEADSHA="$(git rev-parse HEAD 2>/dev/null)" || exit 0
# Already answered for this exact commit: a pull request was created or
# subscribed to while the branch was here, and nothing has been pushed since.
[ "$(cat "$GITDIR/freezemag-pr-cleared" 2>/dev/null)" = "$HEADSHA" ] && exit 0
# The proof: git's own record that a push wrote this tip, and recently.
# The time must come from %gd (the reflog entry's own timestamp, as
# `ref@{1789130766}` under --date=unix), never from %ct, which is the
# commit's date: pushing a branch of older commits would then look stale and
# the guard would silently not arm.
UPREF="$(git rev-parse -q --symbolic-full-name '@{u}' 2>/dev/null)"
if [ -n "$UPREF" ] && [ -f "$GITDIR/logs/$UPREF" ]; then
  ENTRY="$(git log -g -1 --date=unix --format='%H|%gs|%gd' "$UPREF" 2>/dev/null)"
  case "${ENTRY#*|}" in "update by push"*) ;; *) exit 0;; esac
  [ "${ENTRY%%|*}" = "$HEADSHA" ] || exit 0
  TS="${ENTRY##*@\{}"; TS="${TS%\}}"
  case "$TS" in ''|*[!0-9]*) exit 0;; esac
  [ "$(( $(date +%s) - TS ))" -le 300 ] || exit 0
fi
# No reflog for the upstream ref (core.logAllRefUpdates off): fall back to the
# older, noisier test rather than letting a real push through unguarded.
printf '%s\n' "$BR" > "$GITDIR/freezemag-pr-pending"
{
  echo "freezemag guard: the push landed on '$BR'. Nothing else happens until a pull request covers it."
  echo "Now: list the repository's open pull requests for head '$BR'. If one is open, subscribe to it (subscribe_pr_activity). If none is open, create a draft PR against '${DEF:-main}' and subscribe to it. Either tool clears this hold."
  echo "A closed or merged PR does not count. If the branch's PR was merged, restart the branch from '${DEF:-main}' first (see the prepush-merged guard)."
} >&2
exit 2
