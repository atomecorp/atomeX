#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# atomeX cross‑platform setup script (complete version)
# -----------------------------------------------------------------------------
# Usage:   ./setup.sh [mode] [command]
#   mode      opal | wasm          (default: opal)
#   command   setup | run          (default: setup)
#             setup → install/verify deps then run builder.rb
#             run   → *skip* installs and just run builder.rb
# -----------------------------------------------------------------------------
# Examples:
#   ./setup.sh               # full install (opal)
#   ./setup.sh wasm          # full install for wasm
#   ./setup.sh opal run      # skip installs, launch builder.rb directly
# -----------------------------------------------------------------------------
set -euo pipefail

###############################################################################
# 0. Arguments & basic variables
###############################################################################
MODE=${1:-opal}
COMMAND=${2:-setup}

case "$MODE" in
  opal|wasm) :;;
  *) echo "Error: mode must be 'opal' or 'wasm'"; exit 1;;
esac

case "$COMMAND" in
  setup|run) :;;
  *) echo "Error: command must be 'setup' or 'run'"; exit 1;;
esac

echo "Mode sélectionné : $MODE (command: $COMMAND)"

# -- absolute paths ----------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPERS_DIR="$SCRIPT_DIR/sources/helpers"
BUILDER_CMD=(ruby builder.rb --launch --"$MODE")

###############################################################################
# 1. Platform detection & generic helpers
###############################################################################
OS_TYPE="$(uname)"
case "$OS_TYPE" in
  Darwin)                                 OS_TAG="macos"   ;;
  Linux)                                  OS_TAG="linux"   ;;
  FreeBSD)                                OS_TAG="freebsd" ;;
  *MINGW*|*MSYS*|*CYGWIN*)                OS_TAG="windows" ;;
  *)                                      OS_TAG="unknown" ;;
esac

echo "Detected OS: $OS_TYPE ($OS_TAG)"

have_internet() {
  if [[ "$OS_TAG" == "windows" ]]; then
    ping -n 1 -w 1000 1.1.1.1 >NUL 2>&1
  else
    ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1
  fi
}

update_shell_config() {
  local user_shell shell_config
  user_shell=$(basename "${SHELL:-bash}")
  case "$user_shell" in
    zsh)  shell_config="$HOME/.zshrc";;
    fish) shell_config="$HOME/.config/fish/config.fish";;
    *)    shell_config="$HOME/.bashrc";;
  esac
  echo "$shell_config"
}

append_if_not_present() {
  local file=$1 line=$2
  grep -F -- "$line" "$file" &>/dev/null || echo "$line" >> "$file"
}

###############################################################################
# 2. Node.js helpers
###############################################################################
check_nodejs() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    echo "Node.js already installed: $(node -v) / npm $(npm -v)"
    local latest_npm
    latest_npm=$(npm view npm version 2>/dev/null || echo "unknown")
    if [[ $(npm -v) != "$latest_npm" ]]; then
      echo "npm can be updated ($latest_npm available)"; return 1; fi
    return 0
  fi
  return 1
}

install_nodejs() {
  if check_nodejs; then
    if [[ $(npm -v) != $(npm view npm version 2>/dev/null) ]]; then
      echo "Updating npm …"; npm install -g npm@latest; fi
    return 0
  fi

  echo "Installing Node.js & npm …"
  case "$OS_TAG" in
    macos)
      command -v brew >/dev/null || { echo "Install Homebrew first (https://brew.sh/)"; exit 1; }
      brew install node ;;
    linux)
      if   command -v apt-get >/dev/null; then curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs
      elif command -v dnf      >/dev/null; then curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash - && sudo dnf install -y nodejs
      elif command -v pacman   >/dev/null; then sudo pacman -Sy --noconfirm nodejs npm
      else echo "Install Node.js manually for your distribution"; exit 1; fi;;
    freebsd) sudo pkg install -y node npm;;
    windows)
      if command -v choco >/dev/null;  then choco install nodejs -y
      elif command -v scoop >/dev/null; then scoop install nodejs
      else echo "Install Node.js from https://nodejs.org/"; read -rp "Press Enter once Node.js is installed …"; fi;;
    *) echo "Unsupported OS for Node.js auto‑install"; exit 1;;
  esac

  echo "Node $(node -v) / npm $(npm -v) installed"
  npm install -g npm@latest
}

###############################################################################
# 3. Ruby helpers
###############################################################################
install_rbenv() {
  if command -v rbenv >/dev/null 2>&1; then echo "rbenv already installed"; return; fi
  echo "Installing rbenv …"
  case "$OS_TAG" in
    macos) brew install rbenv ruby-build;;
    linux)
      if command -v apt-get >/dev/null; then
        sudo apt-get update && sudo apt-get install -y git build-essential libssl-dev libreadline-dev zlib1g-dev
        [[ -d "$HOME/.rbenv" ]] || git clone https://github.com/rbenv/rbenv.git ~/.rbenv && (cd ~/.rbenv && src/configure && make -C src)
        [[ -d "$HOME/.rbenv/plugins/ruby-build" ]] || git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
      else echo "Install rbenv manually"; exit 1; fi;;
    freebsd) sudo pkg install -y rbenv ruby-build;;
    *) echo "rbenv auto‑install not supported"; exit 1;;
  esac
  local sc; sc=$(update_shell_config)
  append_if_not_present "$sc" 'export PATH="$HOME/.rbenv/bin:$PATH"'
  append_if_not_present "$sc" 'eval "$(rbenv init -)"'
  export PATH="$HOME/.rbenv/bin:$PATH"; eval "$(rbenv init -)"
}

install_latest_ruby() {
  echo "Installing latest Ruby via rbenv …"
  local latest; latest=$(rbenv install -l | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
  [[ -z "$latest" ]] && { echo "Unable to fetch Ruby versions"; exit 1; }
  rbenv install -s "$latest"
  rbenv global "$latest" && rbenv rehash
  echo "Ruby $(ruby -v) installed"
}

install_ruby_windows() {
  if command -v ruby >/dev/null; then echo "Ruby already installed: $(ruby -v)"; return; fi
  echo "Installing Ruby on Windows …"
  if command -v choco >/dev/null; then choco install ruby -y
  elif command -v scoop >/dev/null; then scoop install ruby
  else echo "Please install Ruby from https://rubyinstaller.org/"; read -rp "Press Enter once installed …"; fi
}

install_gems() {
  echo "Installing bundler & project gems …"
  (cd "$HELPERS_DIR" && gem install bundler && bundle install)
}

install_system_deps() {
  case "$OS_TAG" in
    macos) brew install libxml2 libxslt;;
    linux)
      if command -v apt-get >/dev/null; then sudo apt-get install -y libxml2-dev libxslt-dev
      else echo "Install libxml2-dev libxslt-dev manually"; fi;;
    freebsd) sudo pkg install -y libxml2 libxslt;;
    *) :;;
  esac
}

###############################################################################
# 4. Rust & Tauri helpers
###############################################################################
check_rust() { command -v rustc >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; }
install_rust() {
  if check_rust; then echo "Rust already installed: $(rustc --version)"; return; fi
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  append_if_not_present "$(update_shell_config)" 'source "$HOME/.cargo/env"'
}

check_tauri_cli() { cargo install --list 2>/dev/null | grep -q "tauri-cli"; }
install_tauri_cli() { if ! check_tauri_cli; then echo "Installing Tauri CLI …"; cargo install tauri-cli; fi; }

install_tauri_deps() {
  case "$OS_TAG" in
    macos) brew install webkit2png || true;;
    linux)
      if command -v apt-get >/dev/null; then sudo apt-get install -y libwebkit2gtk-4.0-dev build-essential curl wget libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev
      elif command -v dnf >/dev/null; then sudo dnf install -y webkit2gtk3-devel openssl-devel curl wget gtk3-devel libappindicator-gtk3-devel librsvg2-devel
      elif command -v pacman >/dev/null; then sudo pacman -Syu --needed --noconfirm webkit2gtk base-devel curl wget openssl gtk3 libappindicator-gtk3 librsvg
      fi;;
    windows)
      if ! reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" >/dev/null 2>&1; then
        command -v choco >/dev/null && choco install -y microsoft-edge-webview2-runtime || true
      fi
      if ! where cl.exe >/dev/null 2>&1; then
        echo "Install Visual Studio Build Tools (Desktop C++) manually:";
        echo "https://visualstudio.microsoft.com/visual-cpp-build-tools/";
        read -rp "Press Enter once installed …";
      fi;;
    freebsd) :;;
    *) :;;
  esac
}

install_tauri() {
  echo "Setting up Tauri environment …"
  install_rust
  install_tauri_cli
  install_tauri_deps
}

###############################################################################
# 5. Composite actions
###############################################################################
do_platform_setup() {
  case "$OS_TAG" in
    windows)
      install_nodejs; install_ruby_windows; install_gems; install_tauri;;
    macos|linux|freebsd)
      install_nodejs; install_rbenv; install_latest_ruby; install_system_deps; install_gems; install_tauri;;
    *) echo "Unsupported platform $OS_TAG"; exit 1;;
  esac
}

run_builder() {
  echo "==== Launching builder.rb ===="
  (cd "$HELPERS_DIR" && "${BUILDER_CMD[@]}")
}

###############################################################################
# 6. Main execution flow
###############################################################################
if [[ "$COMMAND" == "run" ]]; then
  # Quick path – just run builder.rb (ensure Ruby is present)
  if ! command -v ruby >/dev/null 2>&1; then
    echo "Ruby not found. Run 'setup' first."
    exit 1
  fi
  run_builder
  exit 0
fi

# Full install path (COMMAND == setup)
if have_internet; then
  echo "Internet OK"
  do_platform_setup
  run_builder
else
  echo "Offline mode detected"
  if [[ -d "$SCRIPT_DIR/build" ]]; then
    echo "Using cached build directory"
    run_builder
  else
    echo "No build directory and no connection — aborting"
    exit 1
  fi
fi
