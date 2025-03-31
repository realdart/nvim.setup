#!/bin/bash

set -e

# Define colors for output
GREEN=$(tput setaf 114)
YELLOW=$(tput setaf 221)
RED=$(tput setaf 196)
NC=$(tput sgr0)

# Automate all selections
os_choice="linux"
term_choice="wezterm"
shell_choice="fish"
wm_choice="zellij"
show_details="No"
USER_HOME=$HOME

# Function to display status messages
status_msg() {
  echo -e "${YELLOW}[*] $1${NC}"
}

success_msg() {
  echo -e "${GREEN}[+] $1${NC}"
}

error_msg() {
  echo -e "${RED}[-] $1${NC}"
}

# Function to run commands with output suppression
run_command() {
  if [ "$show_details" = "Yes" ]; then
    eval "$1"
  else
    eval "$1" &>/dev/null
  fi
}

# Install dependencies
install_dependencies() {
  status_msg "Installing system dependencies..."
  if command -v pacman &>/dev/null; then
    run_command "sudo pacman -Syu --noconfirm"
    run_command "sudo pacman -S --needed --noconfirm base-devel curl git wget"
  else
    run_command "sudo apt-get update -y"
    run_command "sudo apt-get install -y build-essential curl git wget"
  fi
}

# Install Homebrew
install_homebrew() {
  if ! command -v brew &>/dev/null; then
    status_msg "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.bashrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.config/fish/config.fish
  else
    success_msg "Homebrew already installed"
  fi
}

# Install WezTerm
install_wezterm() {
  status_msg "Installing WezTerm..."
  if command -v pacman &>/dev/null; then
    run_command "sudo pacman -S --noconfirm wezterm"
  else
    run_command "brew tap wez/wezterm-linuxbrew"
    run_command "brew install wezterm"
  fi

  mkdir -p ~/.config/wezterm
  run_command "cp -f Gentleman.Dots/.wezterm.lua ~/.config/wezterm/wezterm.lua"
}

# Install Fish Shell
install_fish() {
  status_msg "Installing Fish shell..."
  run_command "brew install fish"

  status_msg "Configuring Fish..."
  mkdir -p ~/.config/fish
  run_command "cp -rf Gentleman.Dots/GentlemanFish/fish ~/.config/"
  run_command "cp -f Gentleman.Dots/starship.toml ~/.config/"
}

# Install Zellij
install_zellij() {
  status_msg "Installing Zellij..."
  run_command "cargo install zellij"

  status_msg "Configuring Zellij..."
  mkdir -p ~/.config/zellij
  run_command "cp -rf Gentleman.Dots/GentlemanZellij/zellij/* ~/.config/zellij/"
}

# Install Neovim
install_neovim() {
  status_msg "Installing Neovim..."
  run_command "brew install nvim node npm lazygit ripgrep fd fzf"

  status_msg "Configuring Neovim..."
  mkdir -p ~/.config/nvim
  run_command "cp -rf Gentleman.Dots/GentlemanNvim/nvim/* ~/.config/nvim/"
}

# Main installation flow
install_dependencies
install_homebrew
install_wezterm
install_fish
install_zellij
install_neovim

# Set Fish as default shell
status_msg "Setting Fish as default shell..."
if command -v fish &>/dev/null; then
  FISH_PATH=$(which fish)
  if ! grep -q "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells
  fi
  sudo chsh -s "$FISH_PATH" $USER
else
  error_msg "Failed to set Fish as default shell"
fi

success_msg "Installation completed successfully!"
echo -e "${YELLOW}Please log out and back in for changes to take effect.${NC}"
