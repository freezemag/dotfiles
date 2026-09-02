---
name: adversarial-review
description: Adversarial review of a plan or a diff before building or merging. Finds what is wrong, what will fail in Cem's cloud-only environment, what costs more than it saves, and what contradicts the repo's own rules. Use before any build Cem has asked to be reviewed, and before opening a PR on a non-trivial change.
effort: medium
---
Do not build. Hand the plan (or `git diff` against main) to the freezemag-base reviewer agent with this brief, then relay its findings unchanged and add your own verdict.

The reviewer must attack, in order:
- Contradictions with the repo's CLAUDE.md, its decision log and its constitution. Quote the rule.
- Things that only work on a local machine. Cem works in cloud sessions: no ~/.claude, ephemeral containers, project settings only.
- Cost: tokens, minutes, dependencies. Every dependency is a liability on tour.
- Over-engineering and scaffolding for a future that is not asked for.
- Anything claimed fixed without a screenshot or a test that proves it.

Output: numbered findings, each tagged blocker / should-fix / nit, with the claim, what is actually true, and the one-line fix. Then a three-sentence verdict. Findings marked blocker are answered before any building starts.
