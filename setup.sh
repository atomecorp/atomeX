#!/bin/bash
set -e

echo "==== atomeX Setup Script ===="

# Detect OS via uname
OS_TYPE=$(uname)
echo "Detected OS: $OS_TYPE"

# Determine the shell configuration file (bash or zsh)
update_shell_config() {
  local SHELL_CONFIG=""
  if [[ "$SHELL" == *"zsh" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
  else
    SHELL_CONFIG="$HOME/.bashrc"
  fi
  echo "$SHELL_CONFIG"
}

# Append a line to a file if not already present
append_if_not_present() {
  local FILE=$1
  local LINE=$2
  grep -F -- "$LINE" "$FILE" &>/dev/null || echo "$LINE" >> "$FILE"
}

# Install rbenv and ruby-build for macOS, Linux, and FreeBSD
install_rbenv() {
  if ! command -v rbenv &> /dev/null; then
    echo "rbenv not found. Installing rbenv and ruby-build..."
    case "$OS_TYPE" in
      Darwin)
        if ! command -v brew &> /dev/null; then
          echo "Homebrew not found. Please install it from https://brew.sh/ first."
          exit 1
        fi
        brew install rbenv ruby-build
        ;;
      Linux)
        if command -v apt-get &> /dev/null; then
          sudo apt-get update
          sudo apt-get install -y git build-essential libssl-dev libreadline-dev zlib1g-dev
          if [ ! -d "$HOME/.rbenv" ]; then
            git clone https://github.com/rbenv/rbenv.git ~/.rbenv
            cd ~/.rbenv && src/configure && make -C src
            cd ~
          fi
          if [ ! -d "$HOME/.rbenv/plugins/ruby-build" ]; then
            git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
          fi
        else
          echo "Please install rbenv manually for your Linux distribution."
          exit 1
        fi
        ;;
      FreeBSD)
        sudo pkg update
        sudo pkg install -y rbenv ruby-build
        ;;
      *)
        echo "OS not supported for automatic rbenv installation."
        exit 1
        ;;
    esac
  else
    echo "rbenv is already installed."
  fi

  # Update PATH and initialize rbenv in the shell config file
  if [[ "$OS_TYPE" != "FreeBSD" ]]; then
    local SHELL_CONFIG=$(update_shell_config)
    append_if_not_present "$SHELL_CONFIG" 'export PATH="$HOME/.rbenv/bin:$PATH"'
    append_if_not_present "$SHELL_CONFIG" 'eval "$(rbenv init -)"'
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
  fi
}

# Install the latest stable Ruby via rbenv
install_latest_ruby() {
  echo "Retrieving list of available Ruby versions..."
  LATEST_RUBY=$(rbenv install -l | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tr -d ' ' | tail -1)
  echo "Latest Ruby version available: $LATEST_RUBY"
  if rbenv versions | grep -q "$LATEST_RUBY"; then
    echo "Ruby $LATEST_RUBY is already installed."
  else
    echo "Installing Ruby $LATEST_RUBY ..."
    rbenv install "$LATEST_RUBY"
  fi
  rbenv global "$LATEST_RUBY"
  rbenv rehash
  echo "Ruby version now: $(ruby -v)"
}

# On Windows: attempt to install Ruby automatically using Chocolatey or Scoop.
# If neither package manager is present, automatically install Scoop.
install_ruby_windows() {
  if command -v ruby &> /dev/null; then
    echo "Ruby is already installed. Detected version: $(ruby -v)"
  else
    echo "Ruby not found."
    # Check if Chocolatey or Scoop is installed
    if ! command -v choco &> /dev/null && ! command -v scoop &> /dev/null; then
      echo "No Chocolatey or Scoop found. Attempting to install Scoop..."
      powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -Command "iex (new-object net.webclient).downloadstring('https://get.scoop.sh')"
      if command -v scoop &> /dev/null; then
        echo "Scoop installed successfully."
      else
        echo "Failed to install Scoop automatically."
        echo "Please install Ruby manually from https://rubyinstaller.org/ and ensure it is added to your PATH."
        read -p "Press Enter when Ruby is installed..."
        return
      fi
    fi

    if command -v choco &> /dev/null; then
      echo "Installing Ruby using Chocolatey..."
      choco install ruby -y
    elif command -v scoop &> /dev/null; then
      echo "Installing Ruby using Scoop..."
      scoop install ruby
    else
      echo "No package manager available. Please install Ruby manually from https://rubyinstaller.org/ and add it to your PATH."
      read -p "Press Enter when Ruby is installed..."
    fi
  fi
}

# Install project gems (bundler and Gemfile dependencies)
install_gems() {
  echo "Installing bundler and project gems..."
  gem install bundler
  bundle install
}

# Install system dependencies (libxml2 and libxslt)
install_system_deps() {
  case "$OS_TYPE" in
    Darwin)
      echo "Installing system dependencies on macOS..."
      brew install libxml2 libxslt
      ;;
    Linux)
      echo "Installing system dependencies on Linux..."
      if command -v apt-get &> /dev/null; then
        sudo apt-get install -y libxml2-dev libxslt-dev
      else
        echo "Please install libxml2-dev and libxslt-dev manually."
      fi
      ;;
    FreeBSD)
      echo "Installing system dependencies on FreeBSD..."
      sudo pkg install -y libxml2 libxslt
      ;;
    *)
      echo "No system dependency installation for this OS."
      ;;
  esac
}

# Main branch: execution differs by platform
if [[ "$OS_TYPE" == MINGW* || "$OS_TYPE" == MSYS* || "$OS_TYPE" == CYGWIN* ]]; then
  echo "Windows detected."
  install_ruby_windows
  install_gems
else
  install_rbenv
  install_latest_ruby
  install_system_deps
  install_gems
fi

echo "==== Launching builder.rb ===="
ruby builder.rb --launch
