#!/bin/bash
# Local machine setup. Cloud sessions do not run this; they get the plugin
# from .claude/settings.json in each repo (see README.md).
set -e
mkdir -p ~/.claude
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
echo "~/.claude/CLAUDE.md -> ~/dotfiles/claude/CLAUDE.md"
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add ~/dotfiles 2>/dev/null || true
  claude plugin install freezemag-base@freezemag --scope user 2>/dev/null || true
  echo "freezemag-base plugin installed (user scope)."
fi
