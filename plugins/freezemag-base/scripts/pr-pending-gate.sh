#!/usr/bin/env bash
# PreToolUse for Edit, Write, MultiEdit and Bash. While .git/freezemag-pr-pending
# exists (written by postpush-pr.sh), every edit and command is refused
# until a pull request covers the pushed branch. pr-pending-clear.sh removes
# the marker when Claude creates a PR or subscribes to one.
# Deliberate override: a Bash command that mentions freezemag-pr-pending
# (e.g. rm .git/freezemag-pr-pending) is allowed, so the hold can be lifted
# on purpose with the reason stated in the command.
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" 2>/dev/null || exit 0
GITDIR="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
F="$GITDIR/freezemag-pr-pending"
[ -f "$F" ] || exit 0
IN="$(cat)"
CMD="$(printf '%s' "$IN" | python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("command",""))' 2>/dev/null)"
case "$CMD" in *freezemag-pr-pending*) exit 0;; esac
BR="$(cat "$F")"
{
  echo "freezemag guard: held. '$BR' was pushed and no pull request has been confirmed for it since."
  echo "Create a draft PR for '$BR' (create_pull_request) or subscribe to its open PR (subscribe_pr_activity). That clears the hold. To lift it deliberately: rm $F, with the reason in the same command."
} >&2
exit 2
