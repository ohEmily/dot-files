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

    sudo apt-get install -y curl git nodejs npm python3 python3-pip
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
  else
    echo "llm already installed."
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

  source "$CONFIG_DIR/.env"

  if ! command -v llm >/dev/null 2>&1; then
    echo "llm command not found — cannot configure API keys."
    return
  fi

  local KEY_PATH
  KEY_PATH="$(llm keys path)"
  mkdir -p "$(dirname "$KEY_PATH")"

  jq -n \
    --arg openai "${OPENAI_API_KEY:-}" \
    --arg gemini "${GEMINI_API_KEY:-}" \
    --arg anthropic "${CLAUDE_API_KEY:-}" \
    '{
      openai: $openai,
      gemini: $gemini,
      anthropic: $anthropic
    }' > "$KEY_PATH"

  echo "Wrote llm keys to $KEY_PATH."
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
    # TODO: commit .zshrc and powerlevel10k config from home laptop
    install_llm
    configure_llm_from_env
}

main "$@"
