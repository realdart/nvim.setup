#!/bin/bash
set -euo pipefail

# Configuration Repository
CONFIG_REPO="https://github.com/realdart/nvim.setup.git"
CONFIG_DIR="$HOME/.config-setup-tmp"

# Color definitions
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
NC=$(tput sgr0)

# Status reporting functions
status_msg() { echo -e "${YELLOW}[*] $1${NC}"; }
success_msg() { echo -e "${GREEN}[+] $1${NC}"; }
error_msg() {
  echo -e "${RED}[-] $1${NC}"
  exit 1
}

# Clone configuration files
clone_configs() {
  status_msg "Downloading configuration files..."
  rm -rf "$CONFIG_DIR"
  git clone --depth 1 "$CONFIG_REPO" "$CONFIG_DIR" || error_msg "Failed to clone config repository"
}

# Setup Fish configuration
setup_fish() {
  status_msg "Configuring Fish shell..."
  mkdir -p ~/.config/fish
  cp -rf "$CONFIG_DIR/fish/"* ~/.config/fish/
}

# Setup Zellij configuration
setup_zellij() {
  status_msg "Configuring Zellij..."
  mkdir -p ~/.config/zellij
  cp -rf "$CONFIG_DIR/zellij/"* ~/.config/zellij/
}

# Setup WezTerm configuration
setup_wezterm() {
  status_msg "Configuring WezTerm..."
  mkdir -p ~/.config/wezterm
  cp "$CONFIG_DIR/wezterm/wezterm.lua" ~/.config/wezterm/
}

# Setup Neovim configuration
setup_neovim() {
  status_msg "Configuring Neovim..."
  mkdir -p ~/.config/nvim
  cp -rf "$CONFIG_DIR/nvim/"* ~/.config/nvim/
}

# Main installation function
main() {
  # Clone config files first
  clone_configs

  # Install packages
  status_msg "Installing core dependencies..."
  sudo apt-get update
  sudo apt-get install -y build-essential curl git

  # Install Homebrew
  if ! command -v brew >/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.bashrc
  fi

  # Install Fish
  status_msg "Installing Fish shell..."
  brew install fish
  setup_fish

  # Install Zellij
  status_msg "Installing Zellij..."
  brew install zellij
  setup_zellij

  # Install WezTerm
  status_msg "Installing WezTerm..."
  brew install wezterm
  setup_wezterm

  # Install Neovim
  status_msg "Installing Neovim..."
  brew install neovim
  setup_neovim

  # Set Fish as default shell
  status_msg "Setting Fish as default shell..."
  if ! grep -q "$(which fish)" /etc/shells; then
    command -v fish | sudo tee -a /etc/shells
  fi
  sudo chsh -s "$(which fish)" $USER

  # Cleanup
  rm -rf "$CONFIG_DIR"

  success_msg "Installation complete! Log out and back in to start using your new environment."
}

# Execute main function
main
