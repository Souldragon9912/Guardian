#!/usr/bin/env bash
set -e

# Define colors using tput
red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
yellow=$(tput setaf 3)
nc=$(tput sgr0) # Reset color

# Background Loading Spinner Function
spinner() {
    local pid=$1
    local spin='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "[%c] Loading Installation Assets..." "${spin:$i:1}"
        sleep 0.2
    done
    printf "[${green}✓${nc}] Done!                \n "
}

    UPTIME=$(uptime -p | sed 's/up //')
    USER_IP=$(hostname -I | awk '{print $1}')
    NODE=$(hostname)
    USER=$(whoami)


# Trap system exits gracefully
trap 'clear; echo "Guardian offline."; exit' SIGINT SIGTERM

while true; do
    clear

    # --- The ASCII Art Header ---
    banner=$(cat <<"EOF"
 ██████╗       ██╗   ██╗███████╗███╗   ██╗████████╗ ██████╗ ██╗   ██╗
██╔════╝       ██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔═══██╗╚██╗ ██╔╝
██║  ███╗█████╗██║   ██║█████╗  ██╔██╗ ██║   ██║   ██║   ██║ ╚████╔╝
██║   ██║╚════╝╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ██║   ██║  ╚██╔╝
╚██████╔╝       ╚████╔╝ ███████╗██║ ╚████║   ██║   ╚██████╔╝   ██║
 ╚═════╝         ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝    ╚═╝
EOF
)
echo " "
echo " "
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
    echo -e "  Version: 1.2     |  Name:    Aegis "
    echo -e " ==================================================== "
    echo ""
    echo " Welcome to the ventoy tool
    Here you can install ventoy to a thumbdrive you have or update an existing one."
    
    # --- Define Menu Options ---
    MENU_OPTIONS="Install Ventoy
Update Ventoy
EXIT : Back to Guardian"

    # --- Launch fzf Menu ---
    SELECTION=$(echo "$MENU_OPTIONS" | fzf --height=12 \
                                           --reverse \
                                           --info=hidden \
                                           --header="[ Use Mouse or Arrows. Double-click to select. ]" \
                                           --prompt="Select Module ❯ " \
                                           --pointer="▶" \
                                           --color="fg+:10,bg+:0,hl:2,hl+:2,prompt:4,pointer:1")

    # If user hits escape or cancels fzf
    [[ -z "$SELECTION" ]] && continue

    CHOICE=$(echo "$SELECTION" | awk -F':' '{print $1}' | xargs)

    # --- Route the Choice ---
    case "$CHOICE" in
        "Install Ventoy")
            clear
            echo "${blue}$banner${nc}"
            echo -e "${red}⚠️  WARNING! THIS INSTALLATION WILL COMPLETELY FORMAT THE DRIVE ⚠️${nc}\n"

            while true; do
                read -rp "Are you absolutely sure you want to proceed? (y/n): " -n 1 yn
                echo ""
                case "$yn" in
                    [Yy]) break ;;
                    [Nn]) echo "Installation aborted."; sleep 2; continue 2 ;; # Jumps out to the main menu loop
                    *) echo -e "\n${yellow}[!] Please press y or n.${nc}" ;;
                esac
            done

            echo -e "[*] Pulling Ventoy Linux Release package from GitHub..."

            # Run wget in the background so we can anchor the spinner to its process ID ($!)
            mkdir -p "$HOME/Downloads/Ventoy_interactive"
            cd "$HOME/Downloads/Ventoy_interactive"

            wget -q https://github.com/ventoy/Ventoy/releases/download/v1.0.99/ventoy-1.0.99-linux.tar.gz &
            spinner $! # Hands over to the loading spinner dynamically

            VENTOY_TAR="ventoy-1.0.99-linux.tar.gz"
            echo "[*] Unpacking filesystem nodes..."
            tar -xzf "$VENTOY_TAR"

            VENTOY_DIR="ventoy-1.0.99"
            cd "$VENTOY_DIR" || exit 1

            echo -e "${green}[✓] Launching Ventoy Web Service GUI...${nc}"
            echo "[*] Open http://127.0.0.1:24600 in your browser to flash your USB stick."
            echo "[*] Press Ctrl+C inside this terminal window when done flashing."
            echo "------------------------------------------------------------------"
            sudo bash VentoyWeb.sh
            ;;

        "Update Ventoy")
            clear
            echo "${blue}$banner${nc}"
            if [[ -d "$HOME/Downloads/Ventoy_interactive/ventoy-1.0.99" ]]; then
                echo -e "[*] Navigating to localized execution directory..."
                cd "$HOME/Downloads/Ventoy_interactive/ventoy-1.0.99"
                echo -e "${green}[✓] Executing localized update server...${nc}"
                sudo bash VentoyWeb.sh
            else
                echo -e "${red}[X] Error: Local Ventoy installation directory not found.${nc}"
                echo "Please run 'Install Ventoy' first to fetch compilation binaries."
                read -n 1 -s -r -p "Press any key to return..."
            fi
            ;;

        "EXIT"|"")
            clear
            echo "Guardian offline."
            exit 0
            ;;
    esac
done
