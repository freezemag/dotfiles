#!/usr/bin/env bash
# PostToolUse for the GitHub tools that prove a pull request exists for the
# branch: create_pull_request and subscribe_pr_activity. Removes the hold set
# by postpush-pr.sh. Clears regardless of which repository the tool named:
# in a multi-repo session the project's marker is the only one there is.
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" 2>/dev/null || exit 0
GITDIR="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
rm -f "$GITDIR/freezemag-pr-pending"
exit 0
