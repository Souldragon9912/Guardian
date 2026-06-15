#!/bin/bash

# --- Guardian Suite Setup Manager ---

INSTALL_DIR="$(dirname "$(dirname "$(realpath "$0")")")"

# Colors
green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
nc=$(tput sgr0)

while true; do
    clear
    echo "${cyan}"
    echo "
 ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗ ██╗ █████╗ ███╗   ██╗
██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗██║██╔══██╗████╗  ██║
██║  ███╗██║   ██║███████║██████╔╝██║  ██║██║███████║██╔██╗ ██║
██║   ██║██║   ██║██╔══██║██╔══██╗██║  ██║██║██╔══██║██║╚██╗██║
╚██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝██║██║  ██║██║ ╚████║
 ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝

███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ "
    echo "${nc}"
    echo ""
    echo "1) Install or Update Guardian"
    echo "2) Change System Icon (Hot-Swap)"
    echo "3) Uninstall Guardian Suite"
    echo "4) Exit Manager"
    echo ""
    read -rp "Select an action [1-4]: " choice

    case $choice in
        1)
            echo -e "[*] Initializing Installation / Update Protocol..."
            sleep 1

            # --- UNLOCK PHASE ---
            echo "[i] Disabling existing immutability locks for secure update..."
            sudo chattr -R -i "$INSTALL_DIR" 2>/dev/null || true
            sudo chattr -i /usr/share/pixmaps/guardian-icon.png 2>/dev/null || true
            sudo chattr -i /usr/share/applications/guardian.desktop 2>/dev/null || true

            # --- DEPENDENCY CHECK ---
            echo "[*] Verifying system dependencies..."
            DEPENDENCIES=("fzf" "msmtp" "msmtp-mta" "curl" "ufw" "mailutils")

            for pkg in "${DEPENDENCIES[@]}"; do
                if ! command -v "$pkg" >/dev/null 2>&1 && ! dpkg -l | grep -qw "$pkg"; then
                    echo "    > Missing $pkg. Installing now..."
                    sudo apt-get update > /dev/null 2>&1
                    sudo apt-get install -y "$pkg" > /dev/null 2>&1

                    if [ $? -eq 0 ]; then
                        echo "      [+] $pkg installed successfully."
                    else
                        echo "      [!] ERROR: Failed to install $pkg."
                        exit 1
                    fi
                else
                    echo "    > [✔] $pkg is verified."
                fi
            done
            echo ""

            # --- CORE INSTALLATION ---
            echo "[i] Setting execution permissions..."
            chmod +x "$INSTALL_DIR"/*.sh
            [ -d "$INSTALL_DIR/scripts" ] && chmod +x "$INSTALL_DIR"/scripts/*.sh

            if [ -L /usr/local/bin/guardian ]; then
                echo "[i] Removing previous global link for clean update..."
                sudo rm -f /usr/local/bin/guardian
            fi

            echo "-> Creating global command..."
            sudo ln -s "$INSTALL_DIR/Guardian.sh" /usr/local/bin/guardian

            if [ -f "$INSTALL_DIR/icons/Guardian.png" ]; then
                echo "[i] Refreshing system icon..."
                sudo cp "$INSTALL_DIR/icons/Guardian.png" /usr/share/pixmaps/guardian-icon.png
            fi

            if [ -f "$INSTALL_DIR/Guardian.desktop" ]; then
                echo "[i] Refreshing application launcher shortcut..."
                sudo cp "$INSTALL_DIR/Guardian.desktop" /usr/share/applications/guardian.desktop
                if command -v update-desktop-database >/dev/null 2>&1; then
                    sudo update-desktop-database /usr/share/applications 2>/dev/null || true
                fi
            fi

            # --- LOCKDOWN PHASE ---
            echo "[*] Applying kernel-level immutability locks (Sniper Protocol)..."
            [ -d "$INSTALL_DIR/scripts" ] && sudo chattr -R +i "$INSTALL_DIR/scripts/"
            [ -d "$INSTALL_DIR/icons" ] && sudo chattr -R +i "$INSTALL_DIR/icons/"
            [ -f "$INSTALL_DIR/Guardian.desktop" ] && sudo chattr +i "$INSTALL_DIR/Guardian.desktop"
            [ -f /usr/share/pixmaps/guardian-icon.png ] && sudo chattr +i /usr/share/pixmaps/guardian-icon.png
            [ -f /usr/share/applications/guardian.desktop ] && sudo chattr +i /usr/share/applications/guardian.desktop

            echo -e "${green}[✔] Setup Complete!${nc}"
            echo " 'guardian' is now a full system command. you can now type this in anywhere in the terminal to access guardian, or you can use the app icon from your app menu."

            echo ""
            read -n 1 -s -r -p "Press any key to return to Manager Menu..."
            ;;

        2)
            echo -e "[*] Icon Modification Protocol Initialized..."
            ICON_DIR="$INSTALL_DIR/icons"

            if [ ! -d "$ICON_DIR" ]; then
                echo -e "${red}[X] Error: Icons directory not found at $ICON_DIR.${nc}"
                read -n 1 -s -r -p "Press any key to return..."
                continue
            fi

            # Read all image files into an array
            mapfile -t icon_list < <(find "$ICON_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.ico" \) -printf "%f\n")

            if [ ${#icon_list[@]} -eq 0 ]; then
                echo -e "${red}[X] No valid image files found in $ICON_DIR.${nc}"
                read -n 1 -s -r -p "Press any key to return..."
                continue
            fi

            echo -e "${cyan}Available Icons Detected:${nc}"
            for i in "${!icon_list[@]}"; do
                echo "  $((i+1))) ${icon_list[$i]}"
            done
            echo "  c) Cancel"

            # Auto-open folder to view images
            xdg-open "$ICON_DIR" 2>/dev/null &

            echo ""
            read -rp "Select the number of the icon to deploy: " icon_choice

            if [[ "$icon_choice" == "c" || "$icon_choice" == "C" ]]; then
                echo "[*] Operation cancelled."
                sleep 1
                continue
            fi

            # Validate selection
            if [[ "$icon_choice" =~ ^[0-9]+$ ]] && [ "$icon_choice" -ge 1 ] && [ "$icon_choice" -le "${#icon_list[@]}" ]; then
                SELECTED_ICON="${icon_list[$((icon_choice-1))]}"

                echo "[i] Unlocking global icon registry..."
                sudo chattr -i /usr/share/pixmaps/guardian-icon.png 2>/dev/null || true
                sudo chattr -R -i "$ICON_DIR" 2>/dev/null || true

                echo "[i] Deploying '$SELECTED_ICON' to system..."
                sudo cp "$ICON_DIR/$SELECTED_ICON" /usr/share/pixmaps/guardian-icon.png

                echo "[i] Refreshing desktop environment cache..."
                sudo touch /usr/share/applications/guardian.desktop
                if command -v update-desktop-database >/dev/null 2>&1; then
                    sudo update-desktop-database /usr/share/applications 2>/dev/null || true
                fi

                echo "[*] Re-securing global icon registry & directories..."
                sudo chattr +i /usr/share/pixmaps/guardian-icon.png
                sudo chattr -R +i "$ICON_DIR" 2>/dev/null || true

                echo -e "\n${green}[✔] System Icon Successfully Updated to: $SELECTED_ICON${nc}"
                echo -e "${yellow}(Note: Ubuntu's desktop environment caches UI elements. You may need to log out and log back in for the new icon to appear).${nc}"
            else
                echo -e "${red}[X] Invalid selection.${nc}"
            fi

            echo ""
            read -n 1 -s -r -p "Press any key to return to Manager Menu..."
            ;;

        3)
            echo -e "${red}--- UNINSTALLATION PROTOCOL ---${nc}"
            echo "1) Soft Uninstall: Remove global hooks (Keep Vault & Source Code)"
            echo -e "${red}2) FULL NUKE: Remove everything AND PERMANENTLY DELETE THE VAULT${nc}"
            echo "c) Cancel"
            echo ""
            read -rp "Select uninstallation level [1, 2, c]: " un_choice

            if [[ "$un_choice" == "c" || "$un_choice" == "C" ]]; then
                echo "[*] Uninstall aborted."
                echo ""
                read -n 1 -s -r -p "Press any key to return to Manager Menu..."
                continue
            fi

            # --- THE HUNTER-KILLER TRACKING ---
            GLOBAL_BIN="/usr/local/bin/guardian"
            GLOBAL_ICON="/usr/share/pixmaps/guardian-icon.png"
            GLOBAL_DESKTOP="/usr/share/applications/guardian.desktop"

            if [ -L "$GLOBAL_BIN" ]; then
                CORE_SCRIPT=$(readlink -f "$GLOBAL_BIN")
                CORE_DIR=$(dirname "$CORE_SCRIPT")
            else
                # Fallback: Search the Home directory if the hook was manually deleted
                echo -e "${yellow}[i] Global hook missing. Scanning for Guardian directory...${nc}"
                CORE_DIR=$(find "$HOME" -maxdepth 4 -type d -name "Guardian" 2>/dev/null | head -n 1)
            fi

            if [[ "$un_choice" == "1" ]]; then
                echo -e "[i] Initiating Soft Uninstall..."

                echo "[i] Unlocking system files..."
                sudo chattr -i "$GLOBAL_ICON" 2>/dev/null || true
                sudo chattr -i "$GLOBAL_DESKTOP" 2>/dev/null || true

                # Unlock core directory using the dynamically traced path
                if [ -n "$CORE_DIR" ] && [ -d "$CORE_DIR" ]; then
                     echo "[i] Unlocking core directory at: $CORE_DIR"
                     sudo chattr -R -i "$CORE_DIR" 2>/dev/null || true
                fi

                echo "[i] Eradicating system integration..."
                sudo rm -f "$GLOBAL_BIN"
                sudo rm -f "$GLOBAL_ICON"
                sudo rm -f "$GLOBAL_DESKTOP"
                if command -v update-desktop-database >/dev/null 2>&1; then
                    sudo update-desktop-database /usr/share/applications 2>/dev/null || true
                fi


                echo -e "${green}[✔] Guardian System Hooks Successfully Removed.${nc}"
                echo -e "${yellow}Note: The source files and Vault in '$CORE_DIR' were preserved.${nc}"

                echo ""
                read -n 1 -s -r -p "Press any key to return to Manager Menu..."

            elif [[ "$un_choice" == "2" ]]; then
                echo -e "${red}[!] CRITICAL WARNING: You are about to PERMANENTLY DESTROY the Guardian Vault and all secured assets.${nc}"
                read -rp "Type 'destroy' to confirm total annihilation: " nuke_confirm

                if [[ "$nuke_confirm" == "destroy" ]]; then
                    echo "[i] Unlocking system files..."
                    sudo chattr -i "$GLOBAL_ICON" 2>/dev/null || true
                    sudo chattr -i "$GLOBAL_DESKTOP" 2>/dev/null || true

                    if [ -n "$CORE_DIR" ] && [ -d "$CORE_DIR" ]; then
                        echo "[i] Unlocking target directory: $CORE_DIR"
                        sudo chattr -R -i "$CORE_DIR" 2>/dev/null || true
                    fi

                    echo "[i] Eradicating system integration..."
                    sudo rm -f "$GLOBAL_BIN"
                    sudo rm -f "$GLOBAL_ICON"
                    sudo rm -f "$GLOBAL_DESKTOP"
                    if command -v update-desktop-database >/dev/null 2>&1; then
                        sudo update-desktop-database /usr/share/applications 2>/dev/null || true
                    fi

                    echo -e "${red}[*] Nuking core directory and Vault...${nc}"

                    # --- SANITY CHECK ---
                    if [[ "$CORE_DIR" == "/" || "$CORE_DIR" == "$HOME" || "$CORE_DIR" == "$HOME/Downloads" || "$CORE_DIR" == "$HOME/Desktop" || -z "$CORE_DIR" ]]; then
                        echo -e "${red}[CRITICAL ERROR] Target resolved to a protected system path: $CORE_DIR${nc}"
                        echo -e "${yellow}[!] Nuke aborted to prevent catastrophic data loss.${nc}"
                        read -n 1 -s -r -p "Press any key to exit..."
                        exit 1
                    fi

                    cd
                    sudo rm -rf /Guardian
sleep 2
                    echo -e "${green}[✔] Guardian has been completely uninstalled from this node.${nc}"
                    sleep 1
                    exit 0
                else
                    echo -e "[*] Uninstallation aborted."
                    echo ""
                    read -n 1 -s -r -p "Press any key to return to Manager Menu..."
                fi
            else
                echo -e "${red}[X] Invalid selection.${nc}"
                echo ""
                read -n 1 -s -r -p "Press any key to return to Manager Menu..."
            fi
            ;;

        4|*)
            echo -e "Exiting Manager..."
            sleep 0.5
            exit 0
            ;;
    esac
done
