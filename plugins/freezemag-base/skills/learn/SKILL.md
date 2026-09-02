---
name: learn
description: Record a lesson from a correction, a shipped bug or a repeated ask, in the place that makes it stick: a guard line, a repo lessons line, or a universal lessons line in dotfiles. Use after fixing whatever Cem corrected, and at the end of any bug fix.
effort: small
---
One lesson per run. Write it in one sentence, past tense, saying what went wrong and what to do instead. No narrative.

**1. Classify it**, in this order:
- Can a hook enforce it? A path that must never be edited, a file whose edit needs a check before stopping. Then it is a **guard**: add a `block` or `warn` line to `.claude/freezemag-guards.txt` in this repo. Enforced rules do not recur.
- Is it about this repo only? Then it is a **repo lesson**: append a dated line to `.claude/rules/lessons.md` in this repo (create the file with a one-line heading if missing). Rules files load in every session of this repo.
- Would it have been wrong in any repo? Then it is a **universal lesson**: it belongs in `plugins/freezemag-base/lessons.md` in freezemag/dotfiles.

**2. Write it.** Guard and repo lessons: edit the file and commit it together with the fix, same commit, message ending "Lesson: <the sentence>". Universal lessons: attach freezemag/dotfiles with push access (the `add_repo` tool, then clone), add the line under the heading, push a branch `claude/lesson-<slug>`, open a draft PR titled "Lesson: <the sentence>", and unsubscribe from it. If dotfiles cannot be attached in this session, print the exact line and the file path for Cem to paste, and say so.

**3. Say what you did** in two lines: the sentence, and where it went. Do not restate the fix.

Check first that the lesson is not already there: grep the guards file, the repo lessons file and the universal lessons printed at session start. A duplicate is a sign the existing line is too vague; sharpen it instead of adding another.
