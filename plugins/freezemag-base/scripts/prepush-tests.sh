#!/usr/bin/env bash
# Runs before any `git push` Claude makes. If the repo has an npm "test"
# script, run it; a failure blocks the push (exit 2) and the tail of the
# output is shown to Claude. Set FREEZEMAG_SKIP_PREPUSH=1 to bypass once.
[ "${FREEZEMAG_SKIP_PREPUSH:-}" = "1" ] && exit 0
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" || exit 0
[ -f package.json ] || exit 0
node -e 'const s=require("./package.json").scripts||{};process.exit(s.test?0:1)' 2>/dev/null || exit 0
OUT="$(npm test --silent 2>&1)"; STATUS=$?
if [ $STATUS -ne 0 ]; then
  { echo "freezemag guard: npm test failed, push blocked. Fix or set FREEZEMAG_SKIP_PREPUSH=1 for a deliberate skip. Tail:"; echo "$OUT" | tail -40; } >&2
  exit 2
fi
exit 0
