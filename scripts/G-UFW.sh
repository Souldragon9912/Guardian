#!/bin/bash

# Define colors using tput
red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
nc=$(tput sgr0) # Reset color

# Ensure script is run as root for profile resets
if [ "$EUID" -ne 0 ]; then
  echo -e "${red}[X] Error: UFW configuration requires root privileges.${nc}"
  echo "Please run via the main Guardian menu or use sudo."
  exit 1
fi

# --- 1. Dynamic System Info ---
UPTIME=$(uptime -p | sed 's/up //')
USER_IP=$(hostname -I | awk '{print $1}')
NODE=$(hostname)
# Dynamically get real user even if running sudo
USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$USER" | cut -d: -f6)

# ---------- fzf modifier ----------
export FZF_DEFAULT_OPTS=$'--border=double
  --color=dark'
trap 'clear; echo "Guardian Deactivated."; exit' SIGINT SIGTERM

# --- 2. ASCII Header ---
echo -e "\e[1;36m"
banner=$(
cat <<"EOF"
 ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗ ██╗ █████╗ ███╗   ██╗
██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗██║██╔══██╗████╗  ██║
██║  ███╗██║   ██║███████║██████╔╝██║  ██║██║███████║██╔██╗ ██║
██║   ██║██║   ██║██╔══██║██╔══██╗██║  ██║██║██╔══██║██║╚██╗██║
╚██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝██║██║  ██║██║ ╚████║
 ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝

██╗   ██╗███████╗██╗    ██╗
██║   ██║██╔════╝██║    ██║
██║   ██║█████╗  ██║ █╗ ██║
██║   ██║██╔══╝  ██║███╗██║
╚██████╔╝██║     ╚███╔███╔╝
 ╚═════╝ ╚═╝      ╚══╝╚══╝   Uncomplicated Firewall
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
    echo -e "  Version: 1.2     |  Name:    Aegis "
    echo -e " ==================================================== "
echo ""

# --- Guardian Shield-Navigator v2.1 ---
CONFIG_FILE="$USER_HOME/.guardian_ufw.bak"
PROFILE_DIR="$USER_HOME/Guardian/profiles"

# Profile Check
mkdir -p "$PROFILE_DIR"

get_listeners() {
    ss -tunlp | grep LISTEN | awk '{
        split($7, a, ",");
        split(a[2], b, "=");
        split(a[1], c, "\"");
        print $5, c[2], b[2]
    }' | awk -F'[: ]' '{print $NF, $(NF-1), $(NF-2)}' | sort -V -u
}

while true; do
    # Added BUILD Custom and LOAD Saved to the main menu
    ACTION=$(echo -e "BUILD Custom Profile\nAPPLY Standard Profile\nAPPLY Gaming Profile\nLOAD Saved Profile\n--------------\nOPEN Ports\nCLOSE Ports\n--------------\nRESTORE from Backup\nEXIT" | fzf \
        --header="[ Guardian Firewall Control ]" \
        --height=38% --reverse --prompt="Select Action > ")

    case "$ACTION" in
        "OPEN Ports")
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

        "APPLY Standard Profile")
            echo -e "\n[*] Applying Standard Profile..."
            sudo ufw --force reset >/dev/null 2>&1
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            sudo ufw --force enable
            echo -e "${green}[✔] Standard Profile Active. System is secured for normal internet usage.${nc}"
            read -p "Press Enter to return..."
            ;;

        "APPLY Gaming Profile")
            echo -e "\n[*] Applying Gaming Profile..."
            sudo ufw --force reset >/dev/null 2>&1
            sudo ufw default deny incoming
            sudo ufw default allow outgoing

            echo "[i] Opening Steam Network Ports..."
            sudo ufw allow 27015:27030/tcp >/dev/null 2>&1
            sudo ufw allow 27015:27030/udp >/dev/null 2>&1
            sudo ufw allow 4380/udp >/dev/null 2>&1

            echo "[i] Opening Sandbox & Simulation Ports (Minecraft, BeamMP)..."
            sudo ufw allow 25565/tcp >/dev/null 2>&1
            sudo ufw allow 30814/tcp >/dev/null 2>&1
            sudo ufw allow 30814/udp >/dev/null 2>&1

            sudo ufw --force enable
            echo -e "${green}[✔] Gaming Profile Active. Required multiplayer network ports are open.${nc}"
            read -p "Press Enter to return..."
            ;;

        "BUILD Custom Profile")
            # Create a temporary file to act a "shopping cart" for selected ports
            TEMP_CART=$(mktemp)

            while true; do
                CART_COUNT=$(sort -u "$TEMP_CART" 2>/dev/null | wc -l)

                CATEGORY=$(echo -e "Sysadmin & General\nGaming Platforms\nHomelab & Self-Hosted\n------------------\nAPPLY Profile [$CART_COUNT Selected]\nCANCEL & Trash Profile" | fzf \
                    --reverse \
                    --header="[ Profile Builder | Add services, then click APPLY ]" \
                    --prompt="Select Category > ")

                case "$CATEGORY" in
                    "Sysadmin & General")
                        SYS_MODULES="KDE Connect (recommended to be open for plasma systems) | 1714:1764/tcp 1714:1764/udp
GitHub & Version Control | 22/tcp 443/tcp 9418/tcp
Standard Internet (Web & DNS) | 80/tcp 443/tcp 53/udp
SSH (Secure Shell) | 22/tcp
SMB (Windows File Share) | 445/tcp
FTP (File Transfer) | 21/tcp
RDP (Remote Desktop) | 3389/tcp
MySQL Database | 3306/tcp
PostgreSQL Database | 5432/tcp"

                        SELECTED=$(echo "$SYS_MODULES" | fzf -m --reverse --delimiter="|" --with-nth=1 \
                            --header="[ TAB to Select | ENTER to Add to Cart | ESC to Go Back ]" \
                            --prompt="Sysadmin > ")
                        [[ -n "$SELECTED" ]] && echo "$SELECTED" >> "$TEMP_CART"
                        ;;

                    "Gaming Platforms")
                        GAME_MODULES="Steam Platform | 27015:27030/tcp 27015:27030/udp 4380/udp
Epic Games | 7777:7784/udp 5222/tcp
Riot Games (Valorant / LoL) | 2099/tcp 5222:5223/tcp 5000:5500/udp 8393:8400/tcp
Rockstar Games (GTA Online) | 6672/udp 61455:61458/udp
Minecraft (Java & Bedrock) | 25565/tcp 19132/udp
BeamMP (Simulation) | 30814/tcp 30814/udp
Xbox Live | 3074/tcp 3074/udp
PlayStation Network | 3478:3480/udp
FiveM (GTA V Server) | 30120/tcp 30120/udp"

                        SELECTED=$(echo "$GAME_MODULES" | fzf -m --reverse --delimiter="|" --with-nth=1 \
                            --header="[ TAB to Select | ENTER to Add to Cart | ESC to Go Back ]" \
                            --prompt="Gaming > ")
                        [[ -n "$SELECTED" ]] && echo "$SELECTED" >> "$TEMP_CART"
                        ;;

                    "Homelab & Self-Hosted")
                        LAB_MODULES="Plex Media Server | 32400/tcp 1900/udp 32469/tcp
Jellyfin Media Server | 8096/tcp 8920/tcp 1900/udp 7359/udp
Immich (Photo Backup) | 2283/tcp
Cockpit (System UI) | 9090/tcp
Portainer (Docker UI) | 9443/tcp 8000/tcp
Docker (Daemon API) | 2375/tcp 2376/tcp"

                        SELECTED=$(echo "$LAB_MODULES" | fzf -m --reverse --delimiter="|" --with-nth=1 \
                            --header="[ TAB to Select | ENTER to Add to Cart | ESC to Go Back ]" \
                            --prompt="Homelab > ")
                        [[ -n "$SELECTED" ]] && echo "$SELECTED" >> "$TEMP_CART"
                        ;;

                    APPLY\ Profile*)
                        if [ ! -s "$TEMP_CART" ]; then
                            echo -e "\n${red}[!] Your profile is empty! Please select services first.${nc}"
                            sleep 1.5
                            continue
                        fi

                        # Deduplicate in case the user accidentally added the same thing twice
                        FINAL_SELECTION=$(sort -u "$TEMP_CART")

                        echo -e "\n[*] Compiling Custom Profile..."

                        # Ask to save the profile
                        read -rp "${yellow}Save this profile for future use? (y/n): ${nc}" SAVE_CHOICE
                        if [[ "$SAVE_CHOICE" =~ ^[Yy]$ ]]; then
                            read -rp "Enter profile name (e.g., HomeServer): " PRO_NAME
                            PRO_NAME=$(echo "$PRO_NAME" | tr -d ' /\\') # Sanitize input
                            echo "$FINAL_SELECTION" > "$PROFILE_DIR/$PRO_NAME.ufw"
                            echo -e "${green}[✔] Profile saved as '$PRO_NAME'${nc}"
                        fi

                        # Apply baseline
                        sudo ufw --force reset >/dev/null 2>&1
                        sudo ufw default deny incoming
                        sudo ufw default allow outgoing

                        # The Engine: Read the cart and deploy the rules
                        echo "$FINAL_SELECTION" | while read -r line; do
                            SERVICE_NAME=$(echo "$line" | awk -F'|' '{print $1}' | xargs)
                            PORTS=$(echo "$line" | awk -F'|' '{print $2}' | xargs)

                            for PORT in $PORTS; do
                                sudo ufw allow "$PORT" comment "Guardian: $SERVICE_NAME" >/dev/null 2>&1
                            done
                        done

                        sudo ufw --force enable >/dev/null 2>&1
                        echo -e "${green}[✔] Custom Profile Successfully Deployed.${nc}"
                        rm -f "$TEMP_CART"
                        read -p "Press Enter to return..."
                        clear
                        break
                        ;;

                    "CANCEL & Trash Profile"|"")
                        rm -f "$TEMP_CART"
                        break
                        ;;
                esac
            done
            ;;

        "LOAD Saved Profile")
            # Check if any saved profiles exist
            if [ -z "$(ls -A "$PROFILE_DIR" 2>/dev/null)" ]; then
                echo -e "\n${red}[X] No saved profiles found.${nc}"
                read -n 1 -s -r -p "Build a custom profile first. Press any key..."
                continue
            fi

            SELECTED_PROFILE=$(ls -1 "$PROFILE_DIR" | grep '\.ufw$' | fzf --reverse \
                --header="[ Select a Saved Profile ]" \
                --prompt="Load Profile > ")

            if [[ -n "$SELECTED_PROFILE" ]]; then
                echo -e "\n[*] Loading Profile: ${SELECTED_PROFILE%.ufw}..."

                sudo ufw --force reset >/dev/null 2>&1
                sudo ufw default deny incoming
                sudo ufw default allow outgoing

                # Read from the saved file and apply
                while read -r line; do
                    SERVICE_NAME=$(echo "$line" | awk -F'|' '{print $1}' | xargs)
                    PORTS=$(echo "$line" | awk -F'|' '{print $2}' | xargs)

                    for PORT in $PORTS; do
                        sudo ufw allow "$PORT" comment "Guardian: $SERVICE_NAME" >/dev/null 2>&1
                    done
                done < "$PROFILE_DIR/$SELECTED_PROFILE"

                sudo ufw --force enable >/dev/null 2>&1
                echo -e "${green}[✔] Profile '${SELECTED_PROFILE%.ufw}' Active.${nc}"
                read -p "Press Enter to return..."
            fi
            ;;

        "RESTORE from Backup")
            if [[ -f "$CONFIG_FILE" ]]; then
                echo -n "[*] Restoring Shield configuration..."
                sudo ufw --force reset > /dev/null
                sudo ufw default deny incoming > /dev/null
                sudo ufw default allow outgoing > /dev/null
                sudo ufw limit ssh > /dev/null

                while read -r port; do
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
