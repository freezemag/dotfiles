#!/usr/bin/env bash
# UserPromptSubmit hook. Plain grep, no model call. When Cem's message reads
# as a correction, one line is added to context so the lesson gets recorded
# with the fix instead of being lost with the session.
PROMPT="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("prompt",""))' 2>/dev/null || cat)"
case "$PROMPT" in /freezemag-base:learn*|/learn*|/freezemag-base:retro*|/retro*) exit 0;; esac
if printf '%s' "$PROMPT" | grep -qiE "i told you|i asked you|told you (this|that|before)|still (not|doesn|isn|broken|wrong)|not fixed|(are|is)n'?t .* fixed|doesn'?t work|don'?t work|why (is|are|did|does) (this|that|it|you|there)|you (removed|missed|ignored|forgot|broke)|again\b|redundant|overengineer|over-engineer|this is wrong|not what i asked"; then
  echo "freezemag: this message reads as a correction. Fix it first. Then run /freezemag-base:learn so the lesson is written down (a guard line or a lessons line, in this repo or in dotfiles), and commit it with the fix."
fi
exit 0
