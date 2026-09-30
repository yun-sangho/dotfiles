[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"

export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "/Users/sangho/.bun/_bun" ] && source "/Users/sangho/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# java
export JAVA_HOME="/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# opencode
export PATH=/Users/sangho/.opencode/bin:$PATH

alias gw="git gtr"
alias gwl="git gtr list"
alias gwr="git gtr rm"
alias gwoc="git gtr new --ai"
alias vim="nvim"

eval "$(starship init zsh)"
