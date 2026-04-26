#!/usr/bin/env bash

set -Eeuo pipefail

log() {
  printf '[install] %s\n' "$*"
}

fail() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
else
  fail "Could not read /etc/os-release to detect the distribution."
fi

DISTRO_ID="${ID:-}"
DISTRO_ID="${DISTRO_ID,,}"
DISTRO_LIKE="${ID_LIKE:-}"
DISTRO_LIKE="${DISTRO_LIKE,,}"
WEZTERM_CONFIG_URL="${WEZTERM_CONFIG_URL:-https://raw.githubusercontent.com/Tonymartos/tonys-wezterm-conf/main/.wezterm.lua}"

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  SUDO=()
  TARGET_USER="${SUDO_USER:-root}"
else
  if ! command -v sudo >/dev/null 2>&1; then
    fail "This script requires sudo to install system packages."
  fi

  SUDO=(sudo)
  TARGET_USER="$USER"
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
FONT_ROOT="${TARGET_HOME}/.local/share/fonts"
WEZTERM_CONFIG_TARGET="${TARGET_HOME}/.wezterm.lua"

if [[ -z "$TARGET_HOME" ]]; then
  fail "Could not resolve the target user's HOME directory: $TARGET_USER"
fi

install_apt_repo_for_wezterm() {
  local keyring="/usr/share/keyrings/wezterm-fury.gpg"
  local repo_file="/etc/apt/sources.list.d/wezterm.list"
  local repo_entry='deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *'

  log "Configuring the official WezTerm APT repository..."
  curl -fsSL https://apt.fury.io/wez/gpg.key | "${SUDO[@]}" gpg --yes --dearmor -o "$keyring"
  printf '%s\n' "$repo_entry" | "${SUDO[@]}" tee "$repo_file" >/dev/null
  "${SUDO[@]}" chmod 644 "$keyring"
}

install_nerd_font_release() {
  local asset_name="$1"
  local target_dir="$2"
  local tmp_dir
  local target_path="${FONT_ROOT}/${target_dir}"

  tmp_dir="$(mktemp -d)"

  log "Installing ${target_dir} font..."
  mkdir -p "$target_path"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${asset_name}" -o "${tmp_dir}/${asset_name}"
  unzip -qo "${tmp_dir}/${asset_name}" -d "$target_path"
  rm -rf "$tmp_dir"

  if [[ ${#SUDO[@]} -eq 0 && "$TARGET_USER" != "root" ]]; then
    chown -R "$TARGET_USER:$TARGET_USER" "$target_path"
  fi
}

install_wezterm_config() {
  local backup_path
  local temp_config

  temp_config="$(mktemp)"

  log "Downloading .wezterm.lua from ${WEZTERM_CONFIG_URL}..."
  curl -fsSL "$WEZTERM_CONFIG_URL" -o "$temp_config"

  if [[ -f "$WEZTERM_CONFIG_TARGET" ]] && cmp -s "$temp_config" "$WEZTERM_CONFIG_TARGET"; then
    log "WezTerm config is already up to date; skipping copy."
    rm -f "$temp_config"
    return
  fi

  if [[ -f "$WEZTERM_CONFIG_TARGET" ]]; then
    backup_path="${WEZTERM_CONFIG_TARGET}.bak.$(date +%Y%m%d-%H%M%S)"
    log "Backing up the existing WezTerm config to ${backup_path}..."
    cp "$WEZTERM_CONFIG_TARGET" "$backup_path"
  fi

  log "Installing .wezterm.lua to ${WEZTERM_CONFIG_TARGET}..."
  install -Dm644 "$temp_config" "$WEZTERM_CONFIG_TARGET"
  rm -f "$temp_config"

  if [[ ${EUID:-$(id -u)} -eq 0 && "$TARGET_USER" != "root" ]]; then
    chown "$TARGET_USER:$TARGET_USER" "$WEZTERM_CONFIG_TARGET"

    if [[ -n "${backup_path:-}" && -f "$backup_path" ]]; then
      chown "$TARGET_USER:$TARGET_USER" "$backup_path"
    fi
  fi
}

install_on_arch() {
  log "Installing WezTerm and Nerd Fonts with pacman..."
  "${SUDO[@]}" pacman -Syu --needed --noconfirm \
    wezterm \
    ttf-jetbrains-mono-nerd \
    ttf-firacode-nerd \
    ttf-nerd-fonts-symbols-mono
}

install_on_debian_like() {
  log "Installing base dependencies for Ubuntu/Debian..."
  "${SUDO[@]}" apt-get update
  "${SUDO[@]}" apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    unzip \
    fontconfig

  install_apt_repo_for_wezterm

  log "Installing WezTerm..."
  "${SUDO[@]}" apt-get update
  "${SUDO[@]}" apt-get install -y wezterm

  log "Installing the Nerd Fonts required by ~/.wezterm.lua..."
  install_nerd_font_release "JetBrainsMono.zip" "JetBrainsMonoNerd"
  install_nerd_font_release "FiraCode.zip" "FiraCodeNerd"
  install_nerd_font_release "NerdFontsSymbolsOnly.zip" "SymbolsNerdFont"
  fc-cache -f "$FONT_ROOT"
}

main() {
  if [[ "$DISTRO_ID" == "arch" || "$DISTRO_ID" == "archlinux" || "$DISTRO_LIKE" == *arch* ]]; then
    install_on_arch
  elif [[ "$DISTRO_ID" == "ubuntu" || "$DISTRO_ID" == "debian" || "$DISTRO_LIKE" == *debian* ]]; then
    install_on_debian_like
  else
    fail "Unsupported distribution: ${DISTRO_ID:-unknown}. This script only supports Arch Linux and Ubuntu/Debian derivatives."
  fi

  install_wezterm_config

  log "Installation completed. Restart WezTerm if it was already open."
  log "Available command: wezterm"
}

main "$@"
