#!/bin/bash

 if [ $# -eq 0 ]; then
   default_mode="opal"
 else
   default_mode="$1"
 fi

 echo "Mode sélectionné : $default_mode"



#ruby builder.rb --launch --wasm
if ping -c 1 1.1.1.1 >/dev/null 2>&1; then
  echo "Internet OK"
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

  # Check if Node.js and npm are installed and up to date
  check_nodejs() {
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
      echo "Node.js is already installed."
      NODE_VERSION=$(node -v)
      NPM_VERSION=$(npm -v)
      echo "Current Node.js version: $NODE_VERSION"
      echo "Current npm version: $NPM_VERSION"

      # Check if npm is up to date
      echo "Checking if npm is up to date..."
      local LATEST_NPM=$(npm view npm version 2>/dev/null)
      if [[ "$NPM_VERSION" != "$LATEST_NPM" ]]; then
        echo "npm can be updated from $NPM_VERSION to $LATEST_NPM"
        return 1
      else
        echo "npm is up to date."
        return 0
      fi
    else
      echo "Node.js and/or npm not found."
      return 1
    fi
  }

  # Install Node.js and npm
  install_nodejs() {
    if check_nodejs; then
      # If npm needs update but node is installed
      if [[ $(npm -v) != $(npm view npm version 2>/dev/null) ]]; then
        echo "Updating npm..."
        npm install -g npm@latest
        echo "npm updated to version: $(npm -v)"
      fi
      return 0
    fi

    echo "Installing Node.js and npm..."

    case "$OS_TYPE" in
      Darwin)
        if ! command -v brew &> /dev/null; then
          echo "Homebrew not found. Please install it from https://brew.sh/ first."
          exit 1
        fi
        brew install node
        ;;
      Linux)
        if command -v apt-get &> /dev/null; then
          # For Debian/Ubuntu
          curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
          sudo apt-get install -y nodejs
        elif command -v dnf &> /dev/null; then
          # For Fedora
          curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
          sudo dnf install -y nodejs
        elif command -v pacman &> /dev/null; then
          # For Arch Linux
          sudo pacman -Sy nodejs npm
        else
          echo "Please install Node.js manually for your Linux distribution."
          exit 1
        fi
        ;;
      FreeBSD)
        sudo pkg update
        sudo pkg install -y node npm
        ;;
      MINGW*|MSYS*|CYGWIN*)
        # For Windows
        if command -v choco &> /dev/null; then
          echo "Installing Node.js using Chocolatey..."
          choco install nodejs -y
        elif command -v scoop &> /dev/null; then
          echo "Installing Node.js using Scoop..."
          scoop install nodejs
        else
          echo "No package manager found. Please install Node.js manually from https://nodejs.org/"
          read -p "Press Enter when Node.js is installed..."
        fi
        ;;
      *)
        echo "OS not supported for automatic Node.js installation."
        echo "Please install Node.js manually from https://nodejs.org/"
        exit 1
        ;;
    esac

    # Verify installation
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
      echo "Node.js installed: $(node -v)"
      echo "npm installed: $(npm -v)"

      # Ensure npm is the latest version
      echo "Updating npm to latest version..."
      npm install -g npm@latest
      echo "npm updated to version: $(npm -v)"
    else
      echo "Node.js installation failed or PATH is not set correctly."
      exit 1
    fi
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
    cd ./sources/helpers
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

  # Check if Rust is installed and up to date
  check_rust() {
    if command -v rustc &> /dev/null && command -v cargo &> /dev/null; then
      echo "Rust is already installed."
      RUST_VERSION=$(rustc --version | cut -d' ' -f2)
      echo "Current Rust version: $RUST_VERSION"

      # Check if rustup is installed
      if command -v rustup &> /dev/null; then
        echo "Checking for Rust updates..."
        # Only update if there are updates available (without forcing recompilation)
        UPDATES=$(rustup check 2>&1)
        if [[ "$UPDATES" == *"Up to date"* ]]; then
          echo "Rust is up to date."
        else
          echo "Updating Rust..."
          rustup update
        fi
      fi
      return 0
    else
      return 1
    fi
  }

  # Install Rust using precompiled binaries
  install_rust() {
    if check_rust; then
      return 0
    fi

    echo "Installing Rust..."

    # Use rustup to install precompiled binaries
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

    # Load Rust environment variables
    source "$HOME/.cargo/env"

    # Update shell config to include Rust in PATH if not already there
    local SHELL_CONFIG=$(update_shell_config)
    append_if_not_present "$SHELL_CONFIG" 'source "$HOME/.cargo/env"'

    echo "Rust installed: $(rustc --version)"
    echo "Cargo installed: $(cargo --version)"
  }

  # Check if Tauri CLI is installed and up to date
  check_tauri_cli() {
    if command -v cargo &> /dev/null; then
      if cargo install --list | grep -q "tauri-cli"; then
        echo "Tauri CLI is already installed."

        # Get current version
        CURRENT_VERSION=$(cargo install --list | grep tauri-cli | awk '{print $2}' | tr -d '(v:)')

        # Get latest version from crates.io (this requires curl and jq)
        if command -v curl &> /dev/null && command -v jq &> /dev/null; then
          echo "Checking for Tauri CLI updates..."
          LATEST_VERSION=$(curl -s https://crates.io/api/v1/crates/tauri-cli | jq -r '.crate.max_version')

          if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
            echo "Tauri CLI is up to date (version $CURRENT_VERSION)."
            return 0
          else
            echo "Tauri CLI update available: $CURRENT_VERSION → $LATEST_VERSION"
            return 1
          fi
        else
          # If we can't check, assume it's up to date
          echo "Cannot check for updates. Assuming Tauri CLI is up to date."
          return 0
        fi
      else
        return 1
      fi
    else
      return 1
    fi
  }

  # Install Tauri CLI
  install_tauri_cli() {
    if ! check_tauri_cli; then
      echo "Installing/updating Tauri CLI..."
      cargo install tauri-cli
      echo "Tauri CLI installed: $(cargo install --list | grep tauri-cli)"
    fi
  }

  # Check Tauri dependencies on macOS
  check_macos_tauri_deps() {
    if ! command -v brew &> /dev/null; then
      echo "Homebrew is required but not found."
      return 1
    fi

    # Check WebKit dependency
    if ! brew list webkit2png &> /dev/null; then
      return 1
    fi

    # Check Xcode command line tools
    if ! xcode-select -p &> /dev/null; then
      return 1
    fi

    return 0
  }

  # Check Tauri dependencies on Debian/Ubuntu
  check_debian_tauri_deps() {
    REQUIRED_PKGS=(
      "libwebkit2gtk-4.0-dev"
      "build-essential"
      "curl"
      "wget"
      "libssl-dev"
      "libgtk-3-dev"
      "libayatana-appindicator3-dev"
      "librsvg2-dev"
    )

    for pkg in "${REQUIRED_PKGS[@]}"; do
      if ! dpkg -s "$pkg" &> /dev/null; then
        return 1
      fi
    done

    return 0
  }

  # Check Tauri dependencies on Fedora/RHEL
  check_fedora_tauri_deps() {
    REQUIRED_PKGS=(
      "webkit2gtk3-devel"
      "openssl-devel"
      "curl"
      "wget"
      "gtk3-devel"
      "libappindicator-gtk3-devel"
      "librsvg2-devel"
    )

    for pkg in "${REQUIRED_PKGS[@]}"; do
      if ! rpm -q "$pkg" &> /dev/null; then
        return 1
      fi
    done

    return 0
  }

  # Check Tauri dependencies on Arch Linux
  check_arch_tauri_deps() {
    REQUIRED_PKGS=(
      "webkit2gtk"
      "base-devel"
      "curl"
      "wget"
      "openssl"
      "gtk3"
      "libappindicator-gtk3"
      "librsvg"
    )

    for pkg in "${REQUIRED_PKGS[@]}"; do
      if ! pacman -Q "$pkg" &> /dev/null; then
        return 1
      fi
    done

    return 0
  }

  # Check Tauri dependencies on FreeBSD
  check_freebsd_tauri_deps() {
    REQUIRED_PKGS=(
      "webkit2-gtk3"
      "pkgconf"
      "curl"
      "wget"
      "openssl"
      "gtk3"
      "librsvg2"
    )

    for pkg in "${REQUIRED_PKGS[@]}"; do
      if ! pkg info -e "$pkg" &> /dev/null; then
        return 1
      fi
    done

    return 0
  }

  # Check Tauri dependencies on Windows
  check_windows_tauri_deps() {
    # Check for WebView2
    # Note: This is a simplistic check for WebView2 registry presence
    if ! reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" &> /dev/null; then
      return 1
    fi

    # Check for Visual C++ Build Tools
    # This is a simplistic check by looking for cl.exe
    if ! where cl.exe &> /dev/null; then
      return 1
    fi

    return 0
  }

  # Install Tauri system dependencies based on OS
  install_tauri_deps() {
    echo "Checking Tauri system dependencies..."

    case "$OS_TYPE" in
      Darwin)
        if check_macos_tauri_deps; then
          echo "All Tauri dependencies for macOS are already installed."
        else
          echo "Installing missing Tauri dependencies for macOS..."

          # Install webkit2png if needed
          if ! brew list webkit2png &> /dev/null; then
            brew install webkit2png
          fi

          # Install Xcode command line tools if needed
          if ! xcode-select -p &> /dev/null; then
            echo "Installing Xcode command line tools..."
            xcode-select --install
            echo "Please wait for Xcode command line tools to finish installing, then press Enter to continue..."
            read -r
          fi
        fi
        ;;

      Linux)
        if command -v apt-get &> /dev/null; then
          echo "Debian/Ubuntu-based distribution detected."

          if check_debian_tauri_deps; then
            echo "All Tauri dependencies for Debian/Ubuntu are already installed."
          else
            echo "Installing missing Tauri dependencies..."
            sudo apt-get update
            sudo apt-get install -y \
              libwebkit2gtk-4.0-dev \
              build-essential \
              curl \
              wget \
              libssl-dev \
              libgtk-3-dev \
              libayatana-appindicator3-dev \
              librsvg2-dev
          fi

        elif command -v dnf &> /dev/null; then
          echo "Fedora/RHEL-based distribution detected."

          if check_fedora_tauri_deps; then
            echo "All Tauri dependencies for Fedora/RHEL are already installed."
          else
            echo "Installing missing Tauri dependencies..."
            sudo dnf install -y \
              webkit2gtk3-devel \
              openssl-devel \
              curl \
              wget \
              gtk3-devel \
              libappindicator-gtk3-devel \
              librsvg2-devel
          fi

        elif command -v pacman &> /dev/null; then
          echo "Arch-based distribution detected."

          if check_arch_tauri_deps; then
            echo "All Tauri dependencies for Arch Linux are already installed."
          else
            echo "Installing missing Tauri dependencies..."
            sudo pacman -Syu --needed \
              webkit2gtk \
              base-devel \
              curl \
              wget \
              openssl \
              gtk3 \
              libappindicator-gtk3 \
              librsvg
          fi

        else
          echo "Unsupported Linux distribution. Please install Tauri dependencies manually."
          echo "See: https://tauri.app/v1/guides/getting-started/prerequisites"
        fi
        ;;

      FreeBSD)
        echo "FreeBSD detected."

        if check_freebsd_tauri_deps; then
          echo "All Tauri dependencies for FreeBSD are already installed."
        else
          echo "Installing missing Tauri dependencies..."
          sudo pkg install -y \
            webkit2-gtk3 \
            pkgconf \
            curl \
            wget \
            openssl \
            gtk3 \
            librsvg2
        fi
        ;;

      MINGW*|MSYS*|CYGWIN*)
        echo "Windows detected."

        if check_windows_tauri_deps; then
          echo "All Tauri dependencies for Windows are already installed."
        else
          echo "Installing missing Tauri dependencies for Windows..."

          # For Windows, use package managers if available
          if command -v choco &> /dev/null; then
            echo "Using Chocolatey to install dependencies..."

            # Check and install WebView2 Runtime if not present
            if ! reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" &> /dev/null; then
              choco install -y microsoft-edge-webview2-runtime
            fi

            # Check and install Visual C++ Build Tools if not present
            if ! where cl.exe &> /dev/null; then
              choco install -y visualstudio2019buildtools visualstudio2019-workload-vctools
            fi

          elif command -v scoop &> /dev/null; then
            echo "Using Scoop to install dependencies..."

            # Check and install WebView2 Runtime
            if ! reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" &> /dev/null; then
              scoop bucket add extras
              scoop install msedge-webview2-runtime
            fi

            # For Visual Studio Build Tools, offer guidance as Scoop doesn't have a good package
            if ! where cl.exe &> /dev/null; then
              echo "Please install Visual Studio Build Tools manually from:"
              echo "https://visualstudio.microsoft.com/visual-cpp-build-tools/"
              echo "Make sure to select 'Desktop Development with C++' workload."
              read -p "Press Enter when Visual Studio Build Tools are installed..."
            fi

          else
            echo "No package manager found. Please install the following manually:"
            echo "1. Microsoft WebView2 Runtime: https://developer.microsoft.com/en-us/microsoft-edge/webview2/"
            echo "2. Visual Studio Build Tools: https://visualstudio.microsoft.com/visual-cpp-build-tools/"
            read -p "Press Enter when dependencies are installed..."
          fi
        fi
        ;;

      *)
        echo "Unsupported OS for Tauri. Please install dependencies manually."
        echo "See: https://tauri.app/v1/guides/getting-started/prerequisites"
        ;;
    esac
  }

  # Setup Tauri development environment
  install_tauri() {
    echo "Setting up Tauri development environment..."

    # Install Rust (if not already installed or not up to date)
    install_rust

    # Install Tauri CLI (if not already installed or not up to date)
    install_tauri_cli

    # Install OS-specific dependencies (only if missing)
    install_tauri_deps

    echo "Tauri development environment setup complete!"
  }


  # Main branch: execution differs by platform
  if [[ "$OS_TYPE" == MINGW* || "$OS_TYPE" == MSYS* || "$OS_TYPE" == CYGWIN* ]]; then
    echo "Windows detected."
    install_nodejs
    install_ruby_windows
    install_gems
    install_tauri
  else
    install_nodejs
    install_rbenv
    install_latest_ruby
    install_system_deps
    install_gems
    install_tauri
    echo "==== Launching builder.rb ===="
     ruby builder.rb --launch --$default_mode
  fi
else
  if [ -d build ]; then
    echo "No connection can't check update"
      cd ./sources/helpers
        ruby builder.rb --launch --$default_mode
  else
    echo "No connection unable to install"
  fi
fi


