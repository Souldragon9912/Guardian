#!/bin/bash

# --- Guardian Suite Installer ---

echo -e "🛡️  Installing Guardian Security Suite..."

sleep 2


# 2. Get the absolute path of the directory the installer is in
INSTALL_DIR="$(dirname "$(realpath "$0")")"

# 3. Make all scripts in the directory executable
echo "[i] Setting execution permissions..."
chmod +x "$INSTALL_DIR"/*.sh

# 4. Remove any existing installation link to avoid conflicts
if [ -L /usr/local/bin/guardian ]; then
    echo "[i] Removing previous installation..."
    rm /usr/local/bin/guardian
fi

# 5. Create the new global symbolic link
echo "-> Creating global command..."
ln -s "$INSTALL_DIR/Guardian.sh" /usr/local/bin/guardian

echo -e "[✔] Installation Complete!"
echo "You can now type 'guardian' from anywhere in your terminal."

# 6. Install the Icon
if [ -f "$INSTALL_DIR/icons/Guardian.png" ]; then
    echo "[i] Installing system icon..."
    # /usr/share/pixmaps is the global directory for application icons
    cp "$INSTALL_DIR/icons/Guardian.png" /usr/share/pixmaps/guardian-icon.png
fi

# 7. Install the Desktop Shortcut
if [ -f "$INSTALL_DIR/Guardian.desktop" ]; then
    echo "[i] Installing application launcher shortcut..."
    # /usr/share/applications is where your start menu looks for apps
    cp "$INSTALL_DIR/Guardian.desktop" /usr/share/applications/guardian.desktop

    # Refresh the system's graphical application registry
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database /usr/share/applications 2>/dev/null || true
    fi
fi

echo "[i] Installing dependencies"
sudo apt update && sudo apt install fzf dialog

echo "[✔] fuzzy finder is installed"
sleep 2
echo "[i] Final checks"
sleep 4

echo -e "[✔] Installation Complete!"

