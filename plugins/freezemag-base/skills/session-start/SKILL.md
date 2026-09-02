---
name: session-start
description: Run the session-start checklist for this repo (clean tree, build, tests, recent history, doc drift) and report in under ten lines. Use at the start of any session that will change code.
effort: small
---
Run these, adapting commands to the repo (package.json scripts, Makefile, CMake, pyproject). Delegate the test run to the freezemag-base test-runner agent and the history read to the surveyor agent; they are cheaper than you.

1. `git status`. A dirty tree means an interrupted session: say what is there before touching it.
2. Build, if the repo has a build. Fix a red build before new work.
3. `git log --oneline -15`. Note `fix:` commits that suggest a missing test.
4. Test suite. Red tests are fixed before new work.
5. Doc drift: compare the last commits against CLAUDE.md, README and any methodology doc. Code changed and docs did not is a finding.

Report: one line per item, under ten lines total, findings first. Do not narrate what passed.
