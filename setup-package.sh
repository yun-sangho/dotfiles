#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"

if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Homebrew refuses formulae from third-party taps until they are trusted.
echo "==> Trusting taps from Brewfile..."
sed -nE 's/^tap "([^"]+)".*/\1/p' "$DOTFILES/homebrew/.Brewfile" | while IFS= read -r tap; do
  brew tap "$tap"
  brew trust "$tap"
done

echo "==> Installing brew packages from Brewfile..."
brew bundle --file="$DOTFILES/homebrew/.Brewfile"

# Register the Homebrew JDK with macOS so /usr/libexec/java_home and Gradle
# toolchain detection can find it.
JDK_LINK="/Library/Java/JavaVirtualMachines/openjdk-25.jdk"
if [ ! -e "$JDK_LINK" ]; then
  echo "==> Linking openjdk@25 into /Library/Java/JavaVirtualMachines (sudo)..."
  sudo ln -sfn "$(brew --prefix openjdk@25)/libexec/openjdk.jdk" "$JDK_LINK"
fi
