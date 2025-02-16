#!/bin/bash

set -e
set -o pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Backup function
backup_config() {
  local file=$1
  if [ -f "$file" ] || [ -d "$file" ]; then
    log_info "Backing up $file..."
    cp -r "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
  fi
}

# Check for required commands
check_command() {
  if ! command -v "$1" &>/dev/null; then
    log_error "$1 could not be found"
    return 1
  fi
}

# Detect package manager
detect_package_manager() {
  if command -v apt &>/dev/null; then
    echo "apt"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v yum &>/dev/null; then
    echo "yum"
  else
    log_error "No supported package manager found"
    exit 1
  fi
}

# Ensure the script runs with superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Starting automated setup..."

# Update and install prerequisites
echo "Updating package list..."
apt update -y && apt upgrade -y

# Install Neovim
echo "Installing Neovim..."
apt remove vim -y
if ! command -v brew &>/dev/null; then
  echo "Homebrew not found. Installing Homebrew..."
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
fi
brew install neovim
ln -sf "$(which nvim)" /usr/bin/vim

# Install tmux
echo "Installing tmux..."
apt install tmux -y

# Install eza
echo "Installing eza..."
apt install eza -y

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" </dev/null
else
  echo "Oh My Zsh already installed."
fi

# Clone and setup dotfiles
echo "Cloning dotfiles repository..."
DOTFILES_DIR="$HOME/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
  git clone https://github.com/ItzNesbro/dotfiles "$DOTFILES_DIR"
else
  echo "Dotfiles repository already cloned."
fi

echo "Setting up configuration files..."
mkdir -p ~/.config
cp -r "$DOTFILES_DIR/.config/nvim" ~/.config/nvim
rm -rf ~/.config/tmux
cp -r "$DOTFILES_DIR/.config/tmux" ~/.config/tmux

# Update zshrc with aliases and plugins
echo "Configuring .zshrc..."
cat <<'EOF' >> ~/.zshrc

# Define useful aliases
alias cl="clear"
alias ll="eza -l -g --icons"
alias la="ll -a"
alias g="git"
alias gc="git add . && czg"

# Load zsh plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
EOF

# Install zsh-autosuggestions
echo "Installing zsh-autosuggestions..."
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
else
  echo "zsh-autosuggestions already installed."
fi

# Install zsh-syntax-highlighting
echo "Installing zsh-syntax-highlighting..."
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
else
  echo "zsh-syntax-highlighting already installed."
fi

# Source .zshrc
echo "Sourcing .zshrc..."
source ~/.zshrc

# Install Node.js and npm if not already installed
if ! command -v npm &>/dev/null; then
  echo "Installing Node.js and npm..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt install -y nodejs
fi

# Install czg and minimal-git-cz
echo "Installing czg and minimal-git-cz..."
npm install -g czg minimal-git-cz

echo "Setup complete! Please restart your terminal or run 'source ~/.zshrc' to apply changes."

