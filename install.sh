#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "  linked: $dst"
}

echo "Dotfiles: $DOTFILES"
echo ""

echo "Shell (zsh)"
link "$DOTFILES/zsh/.zshrc"           "$HOME/.zshrc"
link "$DOTFILES/zsh/config/common.zsh" "$HOME/.config/zsh/common.zsh"
link "$DOTFILES/zsh/config/darwin.zsh" "$HOME/.config/zsh/darwin.zsh"
link "$DOTFILES/zsh/config/linux.zsh"  "$HOME/.config/zsh/linux.zsh"

echo "Git"
link "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"

echo "Neovim"
link "$DOTFILES/nvim" "$HOME/.config/nvim"

echo "Tmux"
link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo "Claude"
mkdir -p "$HOME/.claude"
link "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/agents" "$HOME/.claude/agents"
link "$DOTFILES/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
# referenced by pi/settings.json statusLine.command
link "$DOTFILES/claude/statusline-command-llama.sh" "$HOME/.claude/statusline-command-llama.sh"
link "$DOTFILES/claude/bin/claude-spend" "$HOME/.local/bin/claude-spend"
link "$DOTFILES/claude/bin/claude-tmux-status" "$HOME/.local/bin/claude-tmux-status"

echo "Pi"
# settings.json carries the `packages` list; pi installs any missing package
# into ~/.pi/agent/npm on first run, so no explicit install step is needed.
link "$DOTFILES/pi/settings.json"          "$HOME/.pi/agent/settings.json"
link "$DOTFILES/pi/CLAUDE.md"              "$HOME/.pi/agent/CLAUDE.md"
link "$DOTFILES/pi/APPEND_SYSTEM.md"       "$HOME/.pi/agent/APPEND_SYSTEM.md"
link "$DOTFILES/pi/model-router.json"      "$HOME/.pi/agent/model-router.json"
link "$DOTFILES/pi/prompts/handoff.md"     "$HOME/.pi/agent/prompts/handoff.md"
link "$DOTFILES/pi/extensions/tmux-status.ts" "$HOME/.pi/agent/extensions/tmux-status.ts"
link "$DOTFILES/pi/extensions/guardrails.json" "$HOME/.pi/agent/extensions/guardrails.json"
# pi-automode hard-denies agent writes to its own config, so this file is
# created by hand rather than by an agent. Link it only once it exists.
if [[ -f "$DOTFILES/pi/extensions/pi-automode/config.json" ]]; then
    link "$DOTFILES/pi/extensions/pi-automode/config.json" "$HOME/.pi/agent/extensions/pi-automode/config.json"
else
    echo "  SKIPPED: pi/extensions/pi-automode/config.json (missing — see notes below)"
fi

echo "MCP"
link "$DOTFILES/mcp/mcp.json" "$HOME/.config/mcp/mcp.json"

echo "bin"
for script in "$DOTFILES"/bin/*; do
    link "$script" "$HOME/.local/bin/$(basename "$script")"
done

echo ""
echo "Done. Manual steps remaining:"
echo ""

if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    echo "  git identity — create ~/.gitconfig.local:"
    echo "    [user]"
    echo "      name = Evan Zeller"
    echo "      email = evanrzeller@gmail.com"
    echo ""
fi

if [[ ! -f "$DOTFILES/pi/extensions/pi-automode/config.json" ]]; then
    echo "  pi-automode config — create $DOTFILES/pi/extensions/pi-automode/config.json,"
    echo "  then re-run this script. pi-automode deterministically hard-denies agent"
    echo "  writes to its own config, so it cannot be generated for you. Without it,"
    echo "  automode runs on defaults: the classifier falls back to the live session"
    echo "  model (via the router, possibly llama-server) and every in-tree write and"
    echo "  edit is sent to the classifier."
    echo ""
fi

if [[ ! -f "$HOME/.pi/agent/auth.json" ]]; then
    echo "  pi credentials — not in this repo. Run pi and use /login per provider."
    echo "    providers currently configured: anthropic, openai-codex, llama-server"
    echo ""
fi

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo "  tmux plugins — install TPM:"
    echo "    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    echo "    then inside tmux: prefix + I"
    echo ""
fi
