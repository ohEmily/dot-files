#!/bin/bash

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

    echo "Installing other required dependencies via Homebrew..."
    brew list node >/dev/null 2>&1 || brew install node
    brew list python >/dev/null 2>&1 || brew install python
    brew list git >/dev/null 2>&1 || brew install git
    brew list curl >/dev/null 2>&1 || brew install curl
    brew list vim >/dev/null 2>&1 || brew install vim
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

    sudo apt-get install -y curl git nodejs npm python3 python3-pip vim
}

install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "Oh My Zsh already installed at $HOME/.oh-my-zsh. Skipping install."
        return
    fi

    echo "Installing Oh My Zsh..."
    export RUNZSH="no"
    export CHSH="no"
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
            echo 'eval "$(dircolors -b)"' >> "$HOME/.zshrc"
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

configure_llm_from_env() {
  echo "Configuring llm from .env..."

  local CONFIG_DIR
  CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"

  if [[ ! -f "$CONFIG_DIR/.env" ]]; then
    echo "No .env file found — skipping llm config."
    return
  fi

  # shellcheck disable=SC1091
  source "$CONFIG_DIR/.env"

  if ! command -v llm >/dev/null 2>&1; then
    echo "llm command not found — cannot configure API keys."
    return
  fi

  local KEY_PATH
  KEY_PATH="$(llm keys path)"
  mkdir -p "$(dirname "$KEY_PATH")"

  # Create a JSON object with non-empty API keys
  local json="{}"
  
  if [[ -n "${OPENAI_API_KEY:-}" && "$OPENAI_API_KEY" != "" ]]; then
    json=$(jq -n --arg openai "$OPENAI_API_KEY" '. + {openai: $openai}' <<< "$json")
  fi
  
  if [[ -n "${GEMINI_API_KEY:-}" && "$GEMINI_API_KEY" != "" ]]; then
    json=$(jq -n --arg gemini "$GEMINI_API_KEY" '. + {gemini: $gemini}' <<< "$json")
  fi
  
  if [[ -n "${CLAUDE_API_KEY:-}" && "$CLAUDE_API_KEY" != "" ]]; then
    json=$(jq -n --arg anthropic "$CLAUDE_API_KEY" '. + {anthropic: $anthropic}' <<< "$json")
  fi

  # Only write the file if we have valid keys
  if [[ "$json" != "{}" ]]; then
    echo "$json" > "$KEY_PATH"
    echo "Wrote llm API keys to $KEY_PATH."
  else
    echo "No valid API keys found in .env file. Not configuring llm credentials."
  fi

  # Configure llm-cmd if installed
  if command -v llm-cmd >/dev/null 2>&1; then
    echo "Configuring llm-cmd..."
    # Create llm-cmd config directory if it doesn't exist
    local LLM_CMD_CONFIG_DIR="$HOME/.config/llm-cmd"
    mkdir -p "$LLM_CMD_CONFIG_DIR"

    # Create a basic llm-cmd config file
    cat > "$LLM_CMD_CONFIG_DIR/config.yaml" << EOF
# llm-cmd configuration
model: gpt-4  # default model to use
temperature: 0.7  # creativity level (0.0 to 1.0)
max_tokens: 1000  # maximum response length
EOF
    echo "Created llm-cmd configuration at $LLM_CMD_CONFIG_DIR/config.yaml"
  fi
}

install_llm() {
  echo "Installing llm using pipx..."
  if ! command -v pipx >/dev/null 2>&1; then
    echo "Installing pipx..."
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
  fi

  if ! command -v llm >/dev/null 2>&1; then
    pipx install llm
    # Ensure the symlink is created correctly
    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
  else
    echo "llm already installed."
  fi

  # Install llm-cmd
  if ! command -v llm-cmd >/dev/null 2>&1; then
    echo "Installing llm-cmd..."
    pipx install --include-deps llm-cmd
  else
    echo "llm-cmd already installed."
  fi

  configure_llm_from_env
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
    vim +PluginInstall +qall
}

setup_git() {
    echo "Setting up git configuration..."
    local CONFIG_DIR
    CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"

    # Set default branch name to 'main'
    git config --global init.defaultBranch main

    if [[ ! -f "$CONFIG_DIR/.env" ]]; then
        echo "No .env file found — skipping git config."
        return
    fi
    # shellcheck disable=SC1091
    source "$CONFIG_DIR/.env"

    if [[ -n "${GIT_USER_NAME:-}" ]]; then
        git config --global user.name "$GIT_USER_NAME"
    fi

    if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
        git config --global user.email "$GIT_USER_EMAIL"
    fi
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
    elif [[ "$OS" == "linux" ]]; then
        install_dependencies_ubuntu
    fi

    install_oh_my_zsh
    setup_powerlevel10k
    setup_aliases
    setup_git
    setup_vim
    install_llm
}

main "$@"
