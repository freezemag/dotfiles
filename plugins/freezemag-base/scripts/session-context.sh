#!/usr/bin/env bash
# SessionStart hook. Plain-text stdout from a SessionStart hook is added to
# Claude's context, so this is how the universal rules reach every session,
# including cloud sessions that never see ~/.claude. Keep it short: every
# line here is paid for in every session.
cat <<'RULES'
## freezemag base rules (freezemag-base plugin)

WHO. Cem A., artist in Berlin, not a software engineer, works through Claude Code on the web. Everything you write is read by a non-engineer.

REPLIES. First line is the answer. Under 120 words unless he says "full". At most 5 bullets. No headers, no restating his question, no closing summary, no em dashes. Anything longer goes in a file or an artifact; the reply is the link plus three lines. "shorter" or "slop" means cut hard.

INSTRUCTIONS TO HIM. Name the file, the click, the order. Explain a technical term the first time. Give the full content to paste, never "paste the updated file".

STYLE IN UI AND DOCS. British spelling. No exclamation marks. No emoji. No marketing language.

MODELS. The main conversation is for judgment. Delegate file sweeps, greps, catalogue reads and test runs to the freezemag-base surveyor or test-runner agents (haiku); screenshot audits and doc-drift checks to screenshot-auditor and drift-checker (sonnet); adversarial review to reviewer (opus). Give the built-in Explore agent model haiku explicitly.

PULL REQUESTS. Open the PR as a draft, then WATCH it (subscribe to its activity) until it is merged or closed: fix red CI and resolve branch conflicts yourself, automatically and at once, and re-run the checks before every push; keep a check-in scheduled while it is open. Cem merges his own PRs unless he says otherwise. Before every push, read the PR's STATE (open, merged, closed), not only its checks: a merged PR is finished, and a push to its branch is a push to nothing. Anything after the merge restarts from the default branch on the same branch name and gets a new draft PR; the prepush-merged guard blocks the common case, the rule covers the rest. (Amended 2026-09-05 by Cem: "why dont you subscribe and resolve test fails and branch conflicts? these should be done automatically"; until then the rule said not to subscribe.)

WORK. Small edits; one logical change per commit. A screenshot is an object of critique: say what you checked and what looked wrong. When a bug is found: fix it, add a regression test, ask whether a rule is missing, commit the three together. Do not scaffold for v2. Every dependency is a liability on tour.

SKILLS. /freezemag-base:session-start, /freezemag-base:session-end, /freezemag-base:adversarial-review, /freezemag-base:visual-matrix. Per-repo guard rules live in .claude/freezemag-guards.txt.
RULES
# Universal lessons, maintained by /freezemag-base:learn and :retro.
L="$(dirname "$0")/../lessons.md"
[ -f "$L" ] && { echo; cat "$L"; }
exit 0
