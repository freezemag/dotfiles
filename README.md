# dotfiles

Cem A.'s Claude Code kit. This repository is a plugin marketplace with one plugin, `freezemag-base`, enabled from every freezemag repo. It replaces the old `~/.claude/CLAUDE.md` symlink, which cloud sessions never read.

## What the plugin does

- **Rules in every session.** A SessionStart hook prints the universal rules (reply length, who you are working with, style, model delegation, no PR watching) into the session's context. `plugins/freezemag-base/scripts/session-context.sh` is the text; edit it there.
- **Guards.** Before an edit, `block` rules in the repo's `.claude/freezemag-guards.txt` stop it. After an edit, `warn` rules and any `.html`/`.css` edit add a reminder. Before any `git push`, the repo's `npm test` runs and a failure blocks the push.
- **Skills.** `/freezemag-base:session-start`, `/freezemag-base:session-end`, `/freezemag-base:adversarial-review`, `/freezemag-base:visual-matrix`.
- **Agents on cheap models.** `surveyor` and `test-runner` (Haiku), `screenshot-auditor` and `drift-checker` (Sonnet), `reviewer` (Opus).

## Learning from corrections

Lessons persist only in git. Three parts keep them flowing:

- A UserPromptSubmit hook spots a correction in Cem's message ("i told you", "still not", "again", "why is this") and reminds the session to run `/freezemag-base:learn` after the fix. Plain grep, no model call.
- `/freezemag-base:learn` writes one lesson where it sticks: a guard line in the repo's `.claude/freezemag-guards.txt` (enforced), a dated line in the repo's `.claude/rules/lessons.md` (loaded every session in that repo), or a line in `plugins/freezemag-base/lessons.md` here (printed into every session everywhere), via a draft PR.
- `/freezemag-base:retro`, run monthly by Cem, finds lessons that recurred across repos and proposes promoting them here, and universal lessons that can retire.

## Wire a repo (three files)

1. `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "freezemag": { "source": { "source": "github", "repo": "freezemag/dotfiles" } }
  },
  "enabledPlugins": {
    "freezemag-base@freezemag": true
  },
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-start.sh" } ] }
    ]
  }
}
```

2. `.claude/hooks/session-start.sh` (executable), which in a cloud session installs the plugin if it is not already there. Cloud sessions do not auto-install plugins from a GitHub marketplace declared in project settings; the install step is required. Copy the one from `freezemag/atlas`.

3. `.claude/freezemag-guards.txt`, one rule per line:

```
# block <glob> <message>   stops the edit
# warn  <glob> <message>   reminds after the edit
block vendor/** Vendored files are pinned. Re-vendor them, do not edit in place.
warn  round-map.js Run node tests/shot-matrix.js and look at every image before you stop.
```

## Make every cloud session start with the plugin already installed

In claude.ai, open the cloud environment settings and add to the setup script:

```
claude plugin marketplace add freezemag/dotfiles
claude plugin install freezemag-base@freezemag
```

The setup script runs before Claude Code launches and its result is cached, so the per-repo hook above becomes a fallback.

## Getting a change to the plugin into sessions

Two steps, and the first is easy to forget. The marketplace entry carries a `version`, and the plugin documentation says users "only receive updates when you bump this field", so a merged change that keeps the old number reaches nobody. Bump it in both `plugins/freezemag-base/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

Then the cache. A running session keeps the copy it installed, and so does any cloud environment whose setup cache is warm. After merging, rebuild the environment setup cache in the claude.ai environment settings, start a new session, and read the version back with `claude plugin list` before believing the fix is live.

## Local machine

```
git clone git@github.com:freezemag/dotfiles.git ~/dotfiles && ~/dotfiles/setup.sh
```

`claude/CLAUDE.md` is kept for terminal sessions; the plugin is the source of truth for cloud sessions.
