# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) and [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle).

## Layout

```
~/.dotfiles/
├── agents/.agents/AGENTS.md   → global instructions for Codex and Claude Code
├── ghostty/.config/ghostty/    → ~/.config/ghostty
├── nvim/.config/nvim/          → ~/.config/nvim
├── tmux/.tmux.conf             → ~/.tmux.conf
├── zsh/.zshrc                  → ~/.zshrc
├── karabiner/.config/karabiner/karabiner.json  → ~/.config/karabiner/karabiner.json
├── homebrew/.Brewfile          → list of installed brew packages
└── setup.sh                    → bootstrap script for a new machine
```

## New machine setup

```bash
xcode-select --install
git clone https://github.com/<user>/dotfiles ~/.dotfiles
cd ~/.dotfiles && bash setup.sh
```

`setup.sh` also installs nvm and Node.js LTS, JDK 25 (`openjdk@25`), the JetBrains Kotlin LSP, and Go with `golangci-lint`, and asks for `sudo` once to link the JDK into `/Library/Java/JavaVirtualMachines`.

`setup-config.sh` also installs TPM and the plugins declared in your tmux config.
Existing plugins are kept. To run just this step, use `bash ~/.dotfiles/setup-tmux.sh`.

## Set up coding agents

The `agents` package links `~/.agents/AGENTS.md`, `~/.codex/AGENTS.md`, and
`~/.claude/CLAUDE.md` to the shared file at `agents/.agents/AGENTS.md`. Edit that
file and start a new agent session to pick up changes.

To apply just the agent and shell settings on an existing Mac, run:

```bash
bash ~/.dotfiles/setup-config.sh agents zsh
```

If Stow reports a conflict, setup asks before backing up the existing configuration
in `~/.dotfiles/backups/`. Put machine-specific shell settings in `~/.zshrc.local`,
which the shared `.zshrc` loads at the end.

1. Install and sign in to [Claude Code](https://code.claude.com/docs/en/quickstart).
   This setup works with Claude Code on its own. The Codex link is ready if
   you install [Codex](https://developers.openai.com/codex/cli) later.
2. Open a new terminal after setup. The Brewfile installs `hwt` and `direnv`.
   Install the `hwt` skill and session-start hook for Claude Code.

   ```bash
   hwt install claude --lang ko
   hwt doctor
   ```

   On a Mac with Codex, install its skill with
   `npx skills add yun-sangho/hwt --skill hwt --agent codex --global --yes`.
   `hwt install codex` and `hwt install all` can replace the `~/.codex/AGENTS.md` symlink.
   Start Herdr before using `hwt new` to open an agent session. Use
   `hwt new <branch> --no-space` for a checkout without a Herdr session.
3. Install [Ego Lite](https://github.com/citrolabs/ego-lite#quick-start) and open it
   to complete onboarding. Start a new Claude Code session and check that
   `ego-browser` appears in its skill list.

## Daily use

- Edit configs at their normal paths (`~/.zshrc`, `~/.config/nvim/...`) — the symlinks point back into `~/.dotfiles`, so edits are tracked automatically.
- After installing a new brew package, refresh the Brewfile:
  ```bash
  brew bundle dump --describe --force --file=~/.dotfiles/homebrew/.Brewfile
  ```
- Add a new config:
  ```bash
  mkdir -p ~/.dotfiles/<pkg>/<path-from-home>
  mv <existing-config> ~/.dotfiles/<pkg>/<path-from-home>/
  cd ~/.dotfiles && stow <pkg>
  ```
- Remove symlinks for a package: `cd ~/.dotfiles && stow -D <pkg>`

