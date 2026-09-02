---
name: retro
description: Monthly review of lessons across every freezemag repo. Finds lessons that recurred in more than one repo and proposes promoting them to the universal list, and universal lessons that stopped mattering. Run by Cem, on request only.
effort: medium
---
Read-only until Cem approves the proposal.

1. Attach every freezemag repo that has a `.claude/` directory (use the `add_repo` tool for each; read access is enough) and clone them. The list today: atlas, dual-trace, close-read, tycoon, meter, homespot, switchboard, website, auction, burnrate, dotfiles.
2. Hand the sweep to the freezemag-base surveyor agent: collect every line from each repo's `.claude/rules/lessons.md` and `.claude/freezemag-guards.txt`, the universal `plugins/freezemag-base/lessons.md`, and the "Common mistakes" or "Lessons" sections of each CLAUDE.md. Also `git log --since='1 month ago' --format=%s` per repo, keeping subjects that contain "Lesson:", "fix", "again" or "revert".
3. Cluster near-duplicates. A lesson that appears, in any wording, in two or more repos is a promotion candidate. A universal lesson with no matching correction or fix commit in three months is a retirement candidate.
4. Report, under 25 lines: a table of promotion candidates (lesson, repos, the proposed universal wording), retirement candidates, and guards that could replace a prose lesson. Stop and wait.
5. On approval only: open one draft PR to freezemag/dotfiles updating `plugins/freezemag-base/lessons.md`, and one small PR per repo where a prose lesson becomes a guard line. Unsubscribe from every PR opened.
