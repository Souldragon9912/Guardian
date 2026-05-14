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

DESKTOP_FILE="$SCRIPT_DIR/.Guardian.desktop"
ICON_FILE="$SCRIPT_DIR/icons/Guardian.png"

# ---- Fix permissions for all tools ----
find "$SCRIPT_DIR" -type f \( -name "*.sh" -o -name "*.desktop" \) -exec chmod +x {} \;

# ---- Update .desktop icon dynamically ----
if [[ -f "$DESKTOP_FILE" ]]; then
    if grep -q "^Icon=" "$DESKTOP_FILE"; then
        sed -i "s|^Icon=.*|Icon=$ICON_FILE|" "$DESKTOP_FILE"
    else
        echo "Icon=$ICON_FILE" >> "$DESKTOP_FILE"
    fi
fi

# ---- Refresh icon cache (this is important) ----
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

    # --- 2. The ASCII Art Header ---
    # Using 'cat' with EOF is the cleanest way to print multi-line text in bash
    # The \e[1;36m makes it Cyan, \e[0m resets it
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
    echo -e "\e[0m"

echo "${blue}"
echo "$banner"
echo "${nc}"
echo "Welcome $USER"
    # --- 3. System Stats ---
    echo -e "\e[1;30m====================================================\e[0m"
    echo -e " \e[1;37mNode:\e[0m   $NODE"
    echo -e " \e[1;37mIP:\e[0m     $USER_IP"
    echo -e " \e[1;37mStatus:\e[0m Online  |  \e[1;37mUptime:\e[0m $UPTIME"
    echo -e "\e[1;30m====================================================\e[0m"
    echo ""

    # --- 4. Define Menu Options ---
    MENU_OPTIONS="G-SEC : Run System Security Audit (Must be Root)
G-PASS: Audit User Password
G-UFW : Configurator for UFW (Must be Root)
G-Notify: Set-up SMS notifications

EXIT  : Shutdown Guardian"

    # --- 5. Launch fzf Menu (Now with --height) ---
    # --height=12 forces the menu to only use 12 lines
    SELECTION=$(echo "$MENU_OPTIONS" | fzf --height=12 \
                                           --reverse \
                                           --info=hidden \
                                           --header="[ Use Mouse or Arrows. Double-click to select. ]" \
                                           --prompt="Select Module ❯ " \
                                           --pointer="▶" \
                                           --color="fg+:10,bg+:0,hl:2,hl+:2,prompt:4,pointer:1")

    CHOICE=$(echo "$SELECTION" | awk -F':' '{print $1}' | xargs)

    # --- 6. Route the Choice ---
    case "$CHOICE" in
        "G-SEC")  sudo ~/Guardian/scripts/G-Sec.sh; read -n 1 -s -r -p "Press any key to return...";;
        "G-PASS") clear; bash ~/Guardian/scripts/G-pass.sh; read -n 1 -s -r -p "Press any key to return...";;
        "G-UFW")  sudo ~/Guardian/scripts/G-UFW.sh ;;
        "G-Notify") clear; bash ~/Guardian/scripts/G-Notify.sh; read -n 1 -s -r -p "Press any key to return...";;
        "G-TOP")  clear; ./g-top.sh;;
        "G-NET")  clear; ./g-net.sh; read -n 1 -s -r -p "Press any key to return...";;
        "EXIT"|"") clear; echo "Guardian offline."; exit 0;;
    esac
done
