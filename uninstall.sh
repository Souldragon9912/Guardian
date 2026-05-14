#!/bin/bash

# --- Guardian Suite: Uninstaller ---

echo -e "\e[1;31m🛡️  Uninstalling Guardian Security Suite...\e[0m"

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run with sudo: sudo ./uninstall.sh"
  exit 1
fi

# 2. Remove the global symbolic link
if [ -L /usr/local/bin/guardian ]; then
    echo "-> Removing global command (/usr/local/bin/guardian)..."
    rm /usr/local/bin/guardian
fi

# 3. Remove system assets (Icons)
if [ -f /usr/share/pixmaps/guardian-icon.png ]; then
    echo "-> Removing system icon..."
    rm /usr/share/pixmaps/guardian-icon.png
fi

# 4. Remove the Desktop Launcher
if [ -f /usr/share/applications/guardian.desktop ]; then
    echo "-> Removing application launcher..."
    rm /usr/share/applications/guardian.desktop

    # Refresh the desktop database so the icon disappears from the menu immediately
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database /usr/share/applications
    fi
fi

echo -e "\e[1;32m✅ Uninstallation Complete!\e[0m"
echo "Note: The project folder itself was not deleted. You can remove it manually with 'rm -rf'."
