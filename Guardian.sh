#!/usr/bin/env bash
set -e
 # Define colors using tput
red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
nc=$(tput sgr0) # Reset color

# Resolve script directory
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR"

# ---- Fix permissions for all tools ----
find "$SCRIPT_DIR" -type f \( -name "*.sh" -o -name "*.desktop" \) -exec chmod +x {} \;

# ---- Refresh icon cache  ----
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$SCRIPT_DIR" 2>/dev/null || true
fi

# ---- Update .desktop icon dynamically ----
#if [[ -f "$DESKTOP_FILE" ]]; then
 #   if grep -q "^Icon=" "$DESKTOP_FILE"; then
 #       sed -i "s|^Icon=.*|Icon=$ICON_FILE|" "$DESKTOP_FILE"
 #   else
 #       echo "Icon=$ICON_FILE" >> "$DESKTOP_FILE"
 #   fi
#fi

# ---- Refresh icon cache  ----
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$SCRIPT_DIR" 2>/dev/null || true
fi
export FZF_DEFAULT_OPTS=$'--border=double
  --color=dark'
trap 'clear; echo "Guardian Deactivated."; exit' SIGINT SIGTERM

while true; do
    clear

    # --- 1. Dynamic System Info ---
    UPTIME=$(uptime -p | sed 's/up //')
    USER_IP=$(hostname -I | awk '{print $1}')
    NODE=$(hostname)
    USER=$(whoami)

    echo -e "\e[1;36m"
banner=$(
cat <<"EOF"
 ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗ ██╗ █████╗ ███╗   ██╗
██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗██║██╔══██╗████╗  ██║
██║  ███╗██║   ██║███████║██████╔╝██║  ██║██║███████║██╔██╗ ██║
██║   ██║██║   ██║██╔══██║██╔══██╗██║  ██║██║██╔══██║██║╚██╗██║
╚██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝██║██║  ██║██║ ╚████║
 ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
EOF
)
    echo -e " "

# Souldragon912
# Ant2-2

echo "${blue}"
echo "$banner"
echo "${nc}"
echo " Welcome $USER"
    echo -e " ==================================================== "
    echo -e "  Node:    $NODE"
    echo -e "  IP:      $USER_IP"
    echo -e "  Status:  Online  |  Uptime:  $UPTIME"
    echo -e "  Version: 1.1     |  Name:    Aegis "
    echo -e " ==================================================== "
    echo ""

    # --- Define Menu Options ---
    MENU_OPTIONS="------ Root Only tools ------
G-SEC : Run System Security Audit
G-UFW : Configurator for UFW
G-Hardware: Run some hardware tests

------ General Tools ------
G-Vault: Securly encript or zip files
G-PASS: Audit User Password
G-Ventoy: Install or update ventoy

EXIT  : Shutdown Guardian"

    # --- Launch fzf Menu  ---
    # --height=12 forces the menu to use 12 lines. I put 16 to fit the new options.
SELECTION=$(echo "$MENU_OPTIONS" | fzf --height=16 \
                                           --reverse \
                                           --info=hidden \
                                           --header="[ Use Mouse or Arrows. Double-click to select. ]" \
                                           --prompt="Select Module ❯ " \
                                           --pointer="▶" \
                                           --color="fg+:10,bg+:0,hl:2,hl+:2,prompt:4,pointer:1" \
                                           --border-label=" ⚙️ Settings (Press Ctrl+s) " \
                                           --border-label-pos=-2 \
                                           --bind="ctrl-s:execute(bash ~/Guardian/scripts/G-Manager.sh)")

    CHOICE=$(echo "$SELECTION" | awk -F':' '{print $1}' | xargs)

    # --- Route the Choice ---
    case "$CHOICE" in
        "G-SEC")  sudo bash ~/Guardian/scripts/G-Sec.sh; read -n 1 -s -r -p "Press any key to return...";;
        "G-PASS") clear; bash ~/Guardian/scripts/G-pass.sh; read -n 1 -s -r -p "Press any key to return...";;
        "G-UFW")  sudo ~/Guardian/scripts/G-UFW.sh ;;
        "G-Vault") clear; bash ~/Guardian/scripts/G-Vault;;
        "G-Ventoy")  clear; bash ~/Guardian/scripts/G-Ventoy.sh;;
        "G-NET")  clear; ./g-net.sh; read -n 1 -s -r -p "Press any key to return...";;
        "G-Hardware") sudo bash ~/Guardian/scripts/G-Hardware.sh; read -n 1 -s -r -p "Press any key to return...";;
        "EXIT"|"") clear; echo "Guardian offline."; exit 0;;
    esac
done
