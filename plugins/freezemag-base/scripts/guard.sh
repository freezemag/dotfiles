#!/usr/bin/env bash
# Guard hook for Edit/Write/MultiEdit. Mode "pre" runs before the edit and can
# BLOCK it; mode "post" runs after and adds a reminder Claude sees.
# Rules come from <repo>/.claude/freezemag-guards.txt, one per line:
#   block <glob>  <message>
#   warn  <glob>  <message>
# Globs match the path relative to the project root (fnmatch, * crosses /).
# Built-in warn: any .html/.css edit reminds Claude to screenshot.
MODE="${1:-pre}"
if command -v python3 >/dev/null 2>&1; then PY=python3; elif command -v python >/dev/null 2>&1; then PY=python; else exit 0; fi
exec "$PY" "$(dirname "$0")/guard.py" "$MODE"
