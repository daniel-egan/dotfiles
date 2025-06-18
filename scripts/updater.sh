#!/usr/bin/env bash
set -euo pipefail

# Prompt for sudo once, and keep-alive
sudo -v

# Keep-alive: update existing sudo time stamp until script has finished
# (kills itself when script exits)
(
  while true; do
    sudo -n true
    sleep 60
  done
) &>/dev/null &
KEEP_SUDO_ALIVE_PID=$!

cleanup() {
  # kill the keep-alive background loop
  kill "$KEEP_SUDO_ALIVE_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo
if command -v apt &>/dev/null; then
  echo "===== APT Update & Upgrade ====="
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt autoremove -y
  sudo apt autoclean -y
  echo
else
  echo "APT not found; skipping."
fi

echo
if command -v brew &>/dev/null; then
  echo "===== Homebrew Update & Upgrade ====="
  brew update
  brew upgrade
  brew cleanup
else
  echo "Homebrew not found; skipping."
fi

echo
if command -v flatpak &>/dev/null; then
  echo "===== Flatpak Update ====="
  flatpak update -y
else
  echo "Flatpak not found; skipping."
fi

echo
echo "===== All done! ====="
