typeset -U path

for brew_path in "${commands[brew]}" /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x "$brew_path" ]] || continue
  eval "$("$brew_path" shellenv zsh)"
  brew_prefix="${HOMEBREW_PREFIX:-${brew_path:h:h}}"
  break
done

path=("$HOME/.local/bin" $path)
export PATH

autoload -Uz compinit
compinit

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
path=("$BUN_INSTALL/bin" $path)
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

if [[ -n ${brew_prefix:-} ]]; then
  jdk_home="$brew_prefix/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
  if [[ -d "$jdk_home" ]]; then
    export JAVA_HOME="$jdk_home"
    path=("$JAVA_HOME/bin" $path)
  fi
  unset jdk_home
fi
unset brew_path brew_prefix

export GOPATH="${GOPATH:-$HOME/go}"
path=("$GOPATH/bin" $path)

if [[ -d "$HOME/.opencode/bin" ]]; then
  path=("$HOME/.opencode/bin" $path)
fi

if [[ $OSTYPE == darwin* ]]; then
  export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
fi
if [[ -n ${PNPM_HOME:-} ]]; then
  path=("$PNPM_HOME/bin" $path)
fi

alias gw="git gtr"
alias gwl="git gtr list"
alias gwr="git gtr rm"
alias gwoc="git gtr new --ai"
alias vim="nvim"

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

# Keep the terminal identity in Codex tool calls launched from Herdr.
codex() {
  if [[ -n "${HC_TERMINAL_ID:-}" || -n "${HC_TERMINAL_SOCKET:-}" ]]; then
    local arg
    for arg in "$@"; do
      if [[ "$arg" == --no-daemon ]]; then
        command codex "$@"
        return $?
      fi
    done
    command codex --no-daemon "$@"
  else
    command codex "$@"
  fi
}

if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
