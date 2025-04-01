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

# Install Nerd Fonts
install_nerd_fonts() {
  # Create fonts directory
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  # Download and install major Nerd Fonts
  declare -A fonts=(
    ["FiraCode"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.tar.xz"
    ["Iosevka"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Iosevka.tar.xz"
    ["JetBrainsMono"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.tar.xz"
    ["Meslo"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Meslo.tar.xz"
    ["Hack"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.tar.xz"
    ["0xProto"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/0xProto.tar.xz"
  )

  for font in "${!fonts[@]}"; do
    status_msg "Installing $font Nerd Font..."
    curl -L "${fonts[$font]}" -o "/tmp/$font.tar.xz"
    tar -xf "/tmp/$font.tar.xz" -C "$FONT_DIR"
    rm -f "/tmp/$font.tar.xz"
  done

  # Update font cache
  fc-cache -fv
  success_msg "Nerd Fonts installed"
}

# Setup Fish configuration
setup_fish() {
  status_msg "Configuring Fish shell..."
  mkdir -p ~/.config/fish
  cp -rf "$CONFIG_DIR/fish/"* ~/.config/fish/
  # Link Starship config from repository
  status_msg "Linking Starship configuration..."
  cp "$CONFIG_DIR/starship.toml" ~/.config/starship.toml
}

# Setup Zellij configuration
setup_zellij() {
  status_msg "Configuring Zellij..."
  mkdir -p ~/.config/zellij/{layouts,plugins}
  # Copy layout and config
  cp "$CONFIG_DIR/zellij/zellij/layouts/work_OldWorld.kdl" ~/.config/zellij/layouts/
  cp "$CONFIG_DIR/zellij/config.kdl" ~/.config/zellij/
  # Install zjstatus plugin
  if [ ! -f ~/.config/zellij/plugins/zjstatus.wasm ]; then
    curl -LO https://github.com/dj95/zjstatus/releases/download/v0.3.0/zjstatus.wasm
    mv zjstatus.wasm ~/.config/zellij/plugins/
  fi
  # Set default layout
  sed -i 's|default_layout.*|default_layout "work_OldWorld"|' ~/.config/zellij/config.kdl
}

# Setup WezTerm configuration
setup_wezterm() {
  status_msg "Configuring WezTerm..."
  mkdir -p ~/.config/wezterm
  cp "$CONFIG_DIR/wezterm/wezterm.lua" ~/.config/wezterm/
  # Set WezTerm as default terminal
  if ! grep -q "alias terminal=wezterm" ~/.config/fish/config.fish; then
    echo -e "\nalias terminal=wezterm" >>~/.config/fish/config.fish
  fi
}

# Setup Neovim configuration
setup_neovim() {
  status_msg "Configuring Neovim..."
  mkdir -p ~/.config/nvim
  # Clone LazyVim starter if missing
  if [ ! -d "$CONFIG_DIR/nvim" ]; then
    git clone --filter=blob:none --branch=stable https://github.com/LazyVim/starter "$CONFIG_DIR/nvim"
  fi
  # Merge configurations
  cp -rf "$CONFIG_DIR/nvim/"* ~/.config/nvim/
  cp -rf "$CONFIG_DIR/nvim/lua/"* ~/.config/nvim/lua/
  # Install LazyVim dependencies
  nvim --headless "+Lazy! sync" +qa
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

  # Install WezTerm
  status_msg "Installing WezTerm..."
  brew install wezterm
  setup_wezterm
  # Installing Nerd Fonts
  status_msg "Installing Nerd Fonts..."
  install_nerd_fonts
  # Install Fish
  status_msg "Installing Fish shell..."
  brew install fish
  setup_fish
  # Install Starship
  status_msg "Installing Starship..."
  brew install starship
  # Install tmux
  status_msg "Installing tmux..."
  brew install tmux
  # Install Zellij
  status_msg "Installing Zellij..."
  brew install zellij
  setup_zellij
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
