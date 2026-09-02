---
name: session-end
description: Close a working session cleanly: build, tests, coherent git log, CLAUDE.md still true, an honest handover note. Use before stopping work in any repo.
effort: small
---
1. Build and run the tests. Delegate the run to the test-runner agent; report failures verbatim.
2. `git log --oneline -10`. The history must read as a sequence of logical changes; if not, say so, do not rewrite it.
3. Does CLAUDE.md still describe the project after this session? If the session introduced a rule, a file, or removed a feature, update it now.
4. If a task is unfinished, leave a `TODO(next-session):` comment where the next session will find it, and say where.
5. If tests are failing and you are stopping anyway, put a one-line comment at the top of the failing test saying what is wrong.

Report under six lines: state of build and tests, what is unfinished, what changed in CLAUDE.md.
