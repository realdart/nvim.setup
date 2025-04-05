#!/bin/bash
set -euo pipefail

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
    # Can add more fonts if you like
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

setup_fish() {
  status_msg "Configuring Fish shell..."
  mkdir -p ~/.config/fish
  touch ~/.config/fish/config.fish
  cp -rf "$CONFIG_DIR/fish-config/"* ~/.config/fish/
  cp "$CONFIG_DIR/starship.toml" ~/.config/
  echo 'set -gx PATH /home/linuxbrew/.linuxbrew/bin $PATH' >>~/.config/fish/config.fish
  echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >>~/.config/fish/config.fish
}

setup_zellij() {
  status_msg "Configuring Zellij..."
  mkdir -p ~/.config/zellij/{layouts,plugins}
  cp "$CONFIG_DIR/zellij-config/layouts/work_OldWorld.kdl" ~/.config/zellij/layouts/
  cp "$CONFIG_DIR/zellij-config/config.kdl" ~/.config/zellij/
  if [ ! -f ~/.config/zellij/plugins/zjstatus.wasm ]; then
    status_msg "Installing zjstatus plugin..."
    curl -LO https://github.com/dj95/zjstatus/releases/download/v0.3.0/zjstatus.wasm
    mv zjstatus.wasm ~/.config/zellij/plugins/
  fi
  sed -i 's|default_layout.*|default_layout "work_OldWorld"|' ~/.config/zellij/config.kdl
}

setup_neovim() {
  status_msg "Configuring Neovim..."
  mkdir -p ~/.config/nvim
  # Create temporary setup directory
  local NVIM_TEMP_DIR="$CONFIG_DIR/nvim-temp"
  # Clone LazyVim starter as base
  if [ ! -d "$NVIM_TEMP_DIR" ]; then
    git clone --filter=blob:none https://github.com/LazyVim/starter "$NVIM_TEMP_DIR"
  fi
  cp -rf "$NVIM_TEMP_DIR/"* ~/.config/nvim/
  cp -rf "$CONFIG_DIR/nvim-config/"* ~/.config/nvim/
  # Install LazyVim dependencies
  status_msg "Installing Neovim plugins..."
  nvim --headless "+Lazy! sync" +qa
}

setup_wezterm() {
  status_msg "Configuring WezTerm..."
  mkdir -p ~/.config/wezterm
  install_nerd_fonts
  cp "$CONFIG_DIR/wezterm.lua" ~/.config/wezterm/
  # Check font installation
  if ! fc-list | grep -q "0xProto Nerd Font"; then
    error_msg "0xProto Nerd Font not found! Check font installation."
  fi
  # Set as default terminal
  status_msg "Setting WezTerm as default terminal..."
  sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator $(which wezterm) 100
  sudo update-alternatives --set x-terminal-emulator $(which wezterm)
  # Install graphics dependencies
  sudo apt-get install -y libegl-mesa0 libgl1-mesa-dri libvulkan1
}

fish_default() {
  # Set Fish as default shell
  status_msg "Setting Fish as default shell..."
  fish_path=$(which fish)
  if ! grep -q "$fish_path" /etc/shells; then
    echo "$fish_path" | sudo tee -a /etc/shells
  fi
  sudo chsh -s "$fish_path" $USER
}

main() {
  clone_configs
  sudo apt-get update
  sudo apt-get install -y build-essential curl git
  # Install Homebrew
  if ! command -v brew >/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.bashrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.config/fish/config.fish
  fi
  # Install packages
  status_msg "Installing applications..."
  brew install zoxide atuin carapace starship
  brew tap wez/wezterm-linuxbrew
  brew install fish zellij wezterm neovim starship tmux
  # Setup configuration
  setup_wezterm
  setup_fish
  setup_zellij
  setup_neovim
  fish_default
  # Cleanup
  rm -rf "$CONFIG_DIR"
  success_msg "Installation complete! Log out and back in to start using your new environment."
}

main
