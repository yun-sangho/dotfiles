# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) and [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle).

## Layout

```
~/.dotfiles/
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
