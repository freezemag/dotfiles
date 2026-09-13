#!/usr/bin/env bash
# PostToolUse for the GitHub tools that prove a pull request exists for the
# branch: create_pull_request and subscribe_pr_activity, from any MCP server
# that offers them. Removes the hold set by postpush-pr.sh. Clears regardless
# of which repository the tool named: in a multi-repo session the project's
# marker is the only one there is.
#
# It also records the commit the hold was cleared at, so that a later hook
# firing on the same tip does not re-arm it. PostToolUse runs only when the
# tool call succeeded, so a failed subscribe clears nothing.
#
# Honest about what this proves: nothing is read from the tool's input or
# response, so the hold enforces a ritual, not a fact. It cannot be tightened
# in a cloud session, where hooks cannot reach the GitHub API (403).
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" 2>/dev/null || exit 0
GITDIR="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
rm -f "$GITDIR/freezemag-pr-pending"
git rev-parse HEAD > "$GITDIR/freezemag-pr-cleared" 2>/dev/null || true
exit 0
