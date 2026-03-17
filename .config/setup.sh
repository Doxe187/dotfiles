#!/bin/bash

set -e

REPO="https://github.com/Doxe187/dotfiles.git"
CFG_DIR="$HOME/.cfg"

echo "==> Dotfiles Setup"

# ── OS erkennen ────────────────────────────────────────────
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  else
    echo "unknown"
  fi
}

OS=$(detect_os)
echo "==> Erkanntes System: $OS"

# ── Git sicherstellen ──────────────────────────────────────
if ! command -v git &>/dev/null; then
  echo "==> Installiere git ..."
  case "$OS" in
    arch)   sudo pacman -S --noconfirm git ;;
    ubuntu) sudo apt-get update && sudo apt-get install -y git ;;
    *)      echo "ERROR: Unbekanntes OS, bitte git manuell installieren." && exit 1 ;;
  esac
fi

# ── Pakete installieren ────────────────────────────────────
install_packages_arch() {
  if ! command -v yay &>/dev/null; then
    echo "==> Installiere yay ..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
  fi

  PKGS=$(grep -v '^\s*#' "$HOME/packages-arch.txt" | grep -v '^\s*$' | tr '\n' ' ')
  echo "==> Installiere Arch-Pakete ..."
  yay -S --needed --noconfirm $PKGS
}

install_packages_ubuntu() {
  sudo apt-get update

  # Standardpakete
  PKGS=$(grep -v '^\s*#' "$HOME/packages-ubuntu.txt" | grep -v '^\s*$' | tr '\n' ' ')
  echo "==> Installiere Ubuntu-Pakete ..."
  sudo apt-get install -y $PKGS

  # neovim: stable PPA für aktuelle Version
  if ! command -v nvim &>/dev/null || [[ $(nvim --version | head -1 | grep -oP '\d+\.\d+') < "0.9" ]]; then
    echo "==> Installiere neovim via PPA ..."
    sudo add-apt-repository -y ppa:neovim-ppa/stable
    sudo apt-get update && sudo apt-get install -y neovim
  fi

  # starship
  if ! command -v starship &>/dev/null; then
    echo "==> Installiere starship ..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi

  # lazygit
  if ! command -v lazygit &>/dev/null; then
    echo "==> Installiere lazygit ..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm /tmp/lazygit.tar.gz /tmp/lazygit
  fi

  # GitHub CLI
  if ! command -v gh &>/dev/null; then
    echo "==> Installiere GitHub CLI ..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
    sudo apt-get update && sudo apt-get install -y gh
  fi

  # ghostty (kein apt-Paket, aus GitHub Releases)
  if ! command -v ghostty &>/dev/null; then
    echo "==> HINWEIS: ghostty ist auf Ubuntu nicht über apt verfügbar."
    echo "    Manuell installieren: https://github.com/ghostty-org/ghostty/releases"
  fi

  echo "==> HINWEIS: Hyprland/Waybar sind Arch-spezifisch und wurden übersprungen."
}

case "$OS" in
  arch)
    [ -f "$HOME/packages-arch.txt" ] && install_packages_arch || echo "WARNUNG: packages-arch.txt nicht gefunden."
    ;;
  ubuntu)
    [ -f "$HOME/packages-ubuntu.txt" ] && install_packages_ubuntu || echo "WARNUNG: packages-ubuntu.txt nicht gefunden."
    ;;
  *)
    echo "WARNUNG: OS '$OS' nicht unterstützt, überspringe Paketinstallation."
    ;;
esac


# ── Bare Repo klonen ───────────────────────────────────────
if [ -d "$CFG_DIR" ]; then
  echo "==> ~/.cfg existiert bereits, überspringe Clone."
else
  echo "==> Klone Repo nach ~/.cfg ..."
  git clone --bare "$REPO" "$CFG_DIR"
fi

# ── config-Alias in .bashrc ────────────────────────────────
ALIAS_LINE="alias config='/usr/bin/git --git-dir=\$HOME/.cfg/ --work-tree=\$HOME'"
if ! grep -q "alias config=" "$HOME/.bashrc"; then
  echo "" >> "$HOME/.bashrc"
  echo "# Dotfiles bare repo alias" >> "$HOME/.bashrc"
  echo "$ALIAS_LINE" >> "$HOME/.bashrc"
  echo "==> config-Alias in ~/.bashrc eingetragen."
else
  echo "==> config-Alias bereits in ~/.bashrc vorhanden."
fi

# config-Funktion für diese Session
config() {
  /usr/bin/git --git-dir="$CFG_DIR" --work-tree="$HOME" "$@"
}

# Untracked Files ausblenden
config config --local status.showUntrackedFiles no

# ── Dotfiles auschecken ────────────────────────────────────
echo "==> Checke Dotfiles aus ..."
if ! config checkout 2>/dev/null; then
  echo "==> Konflikte gefunden – sichere bestehende Dateien nach ~/.dotfiles-backup ..."
  mkdir -p "$HOME/.dotfiles-backup"
  config checkout 2>&1 \
    | grep "^\s" \
    | awk '{print $1}' \
    | xargs -I{} sh -c 'mkdir -p "$HOME/.dotfiles-backup/$(dirname {})" && mv "$HOME/{}" "$HOME/.dotfiles-backup/{}"'
  config checkout
fi

# ── .bashrc neu laden ──────────────────────────────────────
echo "==> Lade ~/.bashrc ..."
source "$HOME/.bashrc"

echo ""
echo "==> Fertig! Dotfiles sind eingerichtet und config-Alias ist aktiv."
