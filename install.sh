#!/usr/bin/env bash
set -euo pipefail

# Common CLI tools installed on all supported platforms.
# Note: these are installed globally in the system package manager namespace
# (Homebrew/apt), not per-project. Prefer project-local tooling where appropriate.
COMMON_CLI_TOOLS=(
    git
    wget
    ca-certificates
    coreutils
    jq
    tree
    vim
    direnv
)

install_dependencies_mac() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv || /usr/local/bin/brew shellenv)"
    else
        echo "Homebrew already installed."
        brew update
    fi

    if ! command -v zsh >/dev/null 2>&1; then
        echo "Installing zsh via Homebrew..."
        brew install zsh
        set_default_shell_to_zsh
    else
        echo "Zsh is already installed at $(command -v zsh)"
    fi

    # Note: these tools are installed globally via Homebrew in the system namespace,
    # not per-project. Prefer project-local tooling where appropriate.
    echo "Installing core CLI tools via Homebrew..."
    local core_tools=("${COMMON_CLI_TOOLS[@]}" node python)
    for pkg in "${core_tools[@]}"; do
        brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg"
    done

    # Ensure direnv is wired into zsh
    if ! grep -q "direnv hook zsh" "$HOME/.zshrc" 2>/dev/null; then
        direnv hook zsh >> "$HOME/.zshrc"
    fi
}

install_dependencies_ubuntu() {
    echo "Updating apt and installing dependencies."
    sudo apt-get update -y

    if ! command -v zsh >/dev/null 2>&1; then
        echo "Installing zsh via apt."
        sudo apt-get install -y zsh
        set_default_shell_to_zsh
    else
        echo "zsh is already installed at $(command -v zsh)."
    fi

    # Note: these tools are installed globally via apt in the system namespace,
    # not per-project. Prefer project-local tooling where appropriate.
    # COMMON_CLI_TOOLS are shared with macOS; ubuntu_only extends that set to
    # approximate the Homebrew-based setup (e.g., nodejs/npm vs Homebrew's node).
    local ubuntu_only=(
        nodejs
        npm
        python3
        curl # similar to MacOS curl
    )
    local packages=("${COMMON_CLI_TOOLS[@]}" "${ubuntu_only[@]}")
    sudo apt-get install -y "${packages[@]}"

    # Ensure direnv is wired into zsh
    if ! grep -q "direnv hook zsh" "$HOME/.zshrc" 2>/dev/null; then
        direnv hook zsh >> "$HOME/.zshrc"
    fi
}

ensure_uv() {
    if command -v uv >/dev/null 2>&1; then
        echo "uv already installed."
        return 0
    fi

    echo "Installing uv..."
    local OS
    OS="$(detect_os)"

    if [[ "$OS" == "mac" ]] && command -v brew >/dev/null 2>&1; then
        # Prefer Homebrew on macOS when available
        if ! brew list uv >/dev/null 2>&1; then
            brew install uv || {
                echo "Homebrew install of uv failed, falling back to official installer..." >&2
                curl -LsSf https://astral.sh/uv/install.sh | sh
            }
        fi
    else
        # Fallback for Linux and other environments: use the official installer
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
}

install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "Oh My Zsh already installed at $HOME/.oh-my-zsh. Skipping install."
        return
    fi

    echo "Installing Oh My Zsh..."
    export RUNZSH="no"   # don't start a new zsh session after install
    export CHSH="no"      # don't change the default shell automatically
    export KEEP_ZSHRC="yes"  # keep existing ~/.zshrc instead of overwriting it
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        echo "Failed to install Oh My Zsh" >&2
        return 1
    }
}

setup_aliases() {
    # Base ls command with show all files (including hidden files starting with .) by default
    if ! grep -q 'alias ls=' "$HOME/.zshrc"; then
        echo 'alias ls="ls -a"' >> "$HOME/.zshrc"
    fi

    # Add color support for ls
    if [[ "$(detect_os)" == "mac" ]]; then
        if ! grep -q 'alias ls=' "$HOME/.zshrc" || ! grep -q 'ls -aG' "$HOME/.zshrc"; then
            sed -i.bak 's/alias ls="ls -a"/alias ls="ls -aG"/' "$HOME/.zshrc"
        fi
    else
        if ! grep -q 'alias ls=' "$HOME/.zshrc" || ! grep -q 'ls -a --color=auto' "$HOME/.zshrc"; then
            sed -i.bak 's/alias ls="ls -a"/alias ls="ls -a --color=auto"/' "$HOME/.zshrc"
        fi
        # Enable color support of ls and also add handy aliases
        if ! grep -q 'eval.*dircolors' "$HOME/.zshrc"; then
            echo "eval \"$(dircolors -b)\"" >> "$HOME/.zshrc"
        fi
    fi

    # Add color support for grep
    if ! grep -q 'alias grep=' "$HOME/.zshrc"; then
        echo 'alias grep="grep --color=auto"' >> "$HOME/.zshrc"
    fi
}

setup_powerlevel10k() {
    echo "Setting up Powerlevel10k theme..."
    local ZSH_CUSTOM=${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}
    if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    else
        git -C "$ZSH_CUSTOM/themes/powerlevel10k" pull --ff-only || true
    fi

    if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
        sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
    else
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
    fi

    # Copy .p10k.zsh configuration
    local CONFIG_DIR
    CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [[ -f "$CONFIG_DIR/.p10k.zsh" ]]; then
        echo "Copying .p10k.zsh configuration..."
        cp "$CONFIG_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
    else
        echo "Warning: No .p10k.zsh configuration file found in $CONFIG_DIR"
        echo "You can run 'p10k configure' to create a new configuration"
    fi

    # prevent configuration wizard from running on startup
    if ! grep -q 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' "$HOME/.zshrc"; then
        echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> "$HOME/.zshrc"
    fi
}

detect_os() {
  case "$OSTYPE" in
      darwin*) echo "mac" ;;
      linux*) echo "linux" ;;
      *) echo "unknown" ;;
  esac
}

set_default_shell_to_zsh() {
   local CURRENT_SHELL
  CURRENT_SHELL="$(realpath "$SHELL")"
  local TARGET_SHELL
  TARGET_SHELL="$(realpath "$(command -v zsh)")"
 
  if [[ "$CURRENT_SHELL" != "$TARGET_SHELL" ]]; then
    echo "Changing default shell from $CURRENT_SHELL to $TARGET_SHELL. May require admin password."
    chsh -s "$TARGET_SHELL" "$USER"
  else
    echo "✅ Zsh is already the default login shell."
  fi
}

setup_vim() {
    echo "Setting up Vim configuration..."
    local CONFIG_DIR
    CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"

    if [[ ! -d "$HOME/.vim/bundle/Vundle.vim" ]]; then
        echo "Installing Vundle..."
        git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
    fi

    if [[ -f "$CONFIG_DIR/.vimrc" ]]; then
        echo "Copying .vimrc configuration..."
        cp "$CONFIG_DIR/.vimrc" "$HOME/.vimrc"
    else
        echo "Warning: No .vimrc configuration file found in $CONFIG_DIR"
        return 1
    fi

    echo "Installing Vim plugins..."
    vim -E -s +PluginInstall +qall
}

setup_git() {
    echo "Setting up git configuration..."
    local CONFIG_DIR
    CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"

    # Set default branch name to 'main'
    git config --global init.defaultBranch main

    # If git global identity is already configured, respect it and exit early.
    local existing_name existing_email
    existing_name="$(git config --global user.name 2>/dev/null || true)"
    existing_email="$(git config --global user.email 2>/dev/null || true)"

    if [[ -n "$existing_name" && -n "$existing_email" ]]; then
        echo "Git global user.name and user.email already set; leaving existing values in place."
        return
    fi

    # Require a local .env with GIT_USER_NAME and GIT_USER_EMAIL when not already configured.
    if [[ ! -f "$CONFIG_DIR/.env" ]]; then
        echo "Error: No .env file found, and git global user.name/user.email are not configured." >&2
        echo "Create $CONFIG_DIR/.env based on .env.example and set GIT_USER_NAME and GIT_USER_EMAIL." >&2
        exit 1
    fi

    # shellcheck disable=SC1091
    source "$CONFIG_DIR/.env"

    if [[ -z "${GIT_USER_NAME:-}" || -z "${GIT_USER_EMAIL:-}" ]]; then
        echo "Error: GIT_USER_NAME and GIT_USER_EMAIL must be set in $CONFIG_DIR/.env when git globals are unset." >&2
        exit 1
    fi

    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
}

setup_dev_environment_mac() {
    if [[ "$(detect_os)" != "mac" ]]; then
        return 0
    fi

    echo "Installing Docker Desktop (via Homebrew cask)..."
    if ! brew list --cask docker >/dev/null 2>&1; then
        brew install --cask docker || true
    else
        echo "Docker Desktop already installed."
    fi

    echo "Creating standard development directories..."
    mkdir -p "$HOME/dev" "$HOME/bin"
}

main() {
    local OS
    OS=$(detect_os)
    echo "Detected OS: $OS"

    if [[ "$OS" == "unknown" ]]; then
        echo "Unsupported OS. Exiting." >&2
        exit 1
    fi

    if [[ "$OS" == "mac" ]]; then
        install_dependencies_mac
        setup_dev_environment_mac
    elif [[ "$OS" == "linux" ]]; then
        install_dependencies_ubuntu
    fi

    ensure_uv
    install_oh_my_zsh
    setup_powerlevel10k
    setup_aliases
    setup_git
    setup_vim
}

main "$@"
