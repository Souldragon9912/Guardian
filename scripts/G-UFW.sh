#!/bin/bash

 # Define colors using tput
red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
nc=$(tput sgr0) # Reset color

    # --- 1. Dynamic System Info ---
    UPTIME=$(uptime -p | sed 's/up //')
    USER_IP=$(hostname -I | awk '{print $1}')
    NODE=$(hostname)
    USER=$(whoami)

# ---------- fzf modifier ----------
export FZF_DEFAULT_OPTS=$'--border=double
  --color=dark'
trap 'clear; echo "Guardian Deactivated."; exit' SIGINT SIGTERM

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

clear
echo "  "
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
    echo -e "  Version: 1.0     |  Name:    Aegis "
    echo -e " ==================================================== "
    echo ""

# --- Guardian Shield-Navigator v2.1 ---
CONFIG_FILE="$HOME/.guardian_ufw.bak"

# Improved parser to handle process names with commas/quotes
get_listeners() {
    ss -tunlp | grep LISTEN | awk '{
        split($7, a, ",");
        split(a[2], b, "=");
        split(a[1], c, "\"");
        print $5, c[2], b[2]
    }' | awk -F'[: ]' '{print $NF, $(NF-1), $(NF-2)}' | sort -V -u
}

while true; do
    ACTION=$(echo -e "OPEN Ports\nCLOSE Ports\nRESTORE from Backup\nEXIT" | fzf \
        --header="[ Guardian Firewall Control ]" \
        --height=15% --reverse --prompt="Select Action > ")

    case "$ACTION" in
        "OPEN Ports")
            # The preview command now uses escaped double quotes to prevent the EOF error
            SELECTED_PORTS=$(get_listeners | fzf -m --reverse \
                --header="[ TAB to Multi-Select | ESC to Go Back ]" \
                --prompt="Service Search > " \
                --preview "echo -e \"--- Service Info ---\n\nPort: {1}\nProcess: {2}\nPID: {3}\n\nFull Command:\n\$(ps -p {3} -o args= 2>/dev/null)\"" \
                --preview-window=right:50%:wrap)

            if [[ -n "$SELECTED_PORTS" ]]; then
                echo "$SELECTED_PORTS" | while read -r line; do
                    PORT=$(echo "$line" | awk '{print $1}')
                    SERVICE=$(echo "$line" | awk '{print $2}')
                    sudo ufw allow "$PORT" comment "Guardian: $SERVICE"
                    echo "$PORT" >> "$CONFIG_FILE"
                done
                sort -u -o "$CONFIG_FILE" "$CONFIG_FILE"
                sudo ufw --force enable
                read -p "Rules applied. Press Enter to return..."
            fi
            ;;

   "CLOSE Ports")
            RULES=$(sudo ufw status numbered | grep -E '^\[[ 0-9]+\]')
            if [[ -z "$RULES" ]]; then
                echo "[!] No active rules to close."
                sleep 1
                continue
            fi

            RULE_TO_DELETE=$(echo "$RULES" | fzf --reverse --header="[ Select Rule to DELETE | ESC to Go Back ]")

            if [[ -n "$RULE_TO_DELETE" ]]; then
                NUM=$(echo "$RULE_TO_DELETE" | sed 's/\[//;s/\].*//')
                sudo ufw --force delete "$NUM"
                read -p "Rule removed. Press Enter to return..."
            fi
            ;;

    "RESTORE from Backup")
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -n "[*] Restoring Shield configuration..."
        # Reset silently
        sudo ufw --force reset > /dev/null
        sudo ufw default deny incoming > /dev/null
        sudo ufw default allow outgoing > /dev/null
        sudo ufw limit ssh > /dev/null

        # Restore loop - silenced to prevent terminal 'jumping'
        while read -r port; do
            # We add a generic comment back in during restore to keep things organized
            sudo ufw allow "$port" comment "Guardian: Restored" > /dev/null
        done < "$CONFIG_FILE"

        sudo ufw --force enable > /dev/null
        echo " [ DONE ]"

        clear
        echo "[+] Shield successfully restored to baseline."
    else
        echo "[!] No backup found at $CONFIG_FILE"
    fi
    read -p "Press Enter to return to menu..."
    ;;

       "EXIT"|"")
            echo "[*] Exiting Guardian Shield."
            sleep 2
            break
            ;;
    esac
done
