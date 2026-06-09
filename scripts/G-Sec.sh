#!/bin/bash

# this is a system auditor. what this does is scan your system for basic information and test different things.
 # Define colors using tput
red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
nc=$(tput sgr0) # Reset color
# Variables for easy use
CHECK="[\033[0;32m\xE2\x9C\x94\033[0m]" # [✔] in Green
CROSS="[\033[0;31m\xE2\x9C\x98\033[0m]" # [✘] in Red
# itterations
spinner() {
    local pid=$!
    local spin='|/-\'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf " Checking..." "${spin:$i:1}"
        sleep 1
    done
    printf "\r[✓] Done!                            \n"
    sleep 2
}
# --------------------------------------------------------------
ACTUAL_USER=${SUDO_USER:-$USER}

USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

LOG_DIR="$USER_HOME/Guardian/Logs"
LOG_FILE="$LOG_DIR/Audit-log.txt"

mkdir -p "$LOG_DIR"
# --------------------------------------------------------------

echo -e "$CHECK Audit Complete"
echo -e "$CROSS Vulnerability Found"
banner=$(cat <<"EOF"
███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗
██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝
███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝
╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝
███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║
╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝

 █████╗ ██╗   ██╗██████╗ ██╗████████╗
██╔══██╗██║   ██║██╔══██╗██║╚══██╔══╝
███████║██║   ██║██║  ██║██║   ██║
██╔══██║██║   ██║██║  ██║██║   ██║
██║  ██║╚██████╔╝██████╔╝██║   ██║
╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝   ╚═╝
EOF
)

echo "$banner" > "$LOG_FILE"

# ====================================================================================================================================
#                                                               START OF SCRIPT
# ====================================================================================================================================
clear

# ROOT CHECK
if [ "$EUID" -ne 0 ]; then
  whiptail --title "Error" --msgbox "In order for the audit to continue, this must be run as root." 8 45
  exit 1
fi

# banner paste
echo "${blue}"
echo "$banner"
echo "${nc}"

    echo "welcome to the system auditor!
here we will run a few tests to make sure your system is not only up-to-date, but safe."
echo
echo
sleep 2

clear
echo "${blue}"
echo "$banner"
echo "${nc}"
  echo "welcome to the system auditor!
here we will run a few tests to make sure your system is not only up-to-date, but safe."

# --- SYSTEM IDENTITY HEADER ---
echo "${cyan}"
cat <<"EOF" | tee -a "$LOG_FILE"
==========================================
        SYSTEM AUDIT IDENTITY
==========================================
EOF
echo "${nc}"

OS_NAME=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
KERNEL=$(uname -r)
CURRENT_SHELL=$SHELL
AUDIT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# adding to audit file
echo -e "AUDIT TIME : $AUDIT_TIME" | tee -a "$LOG_FILE"
echo -e "OS NAME    : $OS_NAME"    | tee -a "$LOG_FILE"
echo -e "KERNEL VER : $KERNEL"     | tee -a "$LOG_FILE"
echo -e "SHELL ENV  : $CURRENT_SHELL" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
sleep 1

# pasword check section
clear
# banner paste
echo "${blue}"
echo "$banner"
echo "${nc}"

 echo "For this next step, we will need your password. It will be used to check if it's strong enough."

echo "${nc}"

sleep 3 &
spinner echo "checking systenm-wide passwords"
#----- FULL SYSTEM PASSWD CHECK -----
echo -e "\n[ SYSTEM-WIDE PASSWORD REPORT ]" | tee -a "$LOG_FILE"

awk -F: '($3 == 0 || $3 >= 1000) && $1 != "nobody" {print $1}' /etc/passwd | while read user; do

    echo "--------------------------------" | tee -a "$LOG_FILE"
    echo "Checking Account: $user" | tee -a "$LOG_FILE"

    # 1. Get the last change date
    LAST_CHANGE=$(sudo chage -l "$user" | grep "Last password change" | cut -d: -f2)

    # 2. Check if the password is set to expire
    EXPIRES=$(sudo chage -l "$user" | grep "Password expires" | cut -d: -f2)

    # 3. Check for Account Lock status
    # 'passwd -S' shows 'L' for locked, 'P' for usable password
    STATUS=$(sudo passwd -S "$user" | awk '{print $2}')

    echo "  -> Last Changed : $LAST_CHANGE" | tee -a "$LOG_FILE"
    echo "  -> Expiration   : $EXPIRES"     | tee -a "$LOG_FILE"

    if [ "$STATUS" == "NP" ]; then
        echo "${red}" " -> Status       : [WARNING] This user has no password"     | tee -a "$LOG_FILE"
    else
        echo "  -> Status       : [ACTIVE/LOCKED] " | tee -a "$LOG_FILE"
    fi
done
echo "${nc}"
    echo "---------------------------------------------" >> "$LOG_FILE"
    echo "password section complete. Moving on to ssh.." >> "$LOG_FILE"
    echo "---------------------------------------------" >> "$LOG_FILE"

sleep 1

clear
# banner paste
echo "${blue}"
echo "$banner"
echo "${nc}"
sleep 2

# ================= SSH section ===============
clear
# banner paste
echo "${blue}"
echo "$banner"
echo "${nc}"

echo "[*] Auditing SSH Configuration..."
if [ ! -f /etc/ssh/sshd_config ]; then
    echo "${yellow}" "[!] SSH config not found. Skipping..." "${nc}" | tee -a "$LOG_FILE"
else
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
        echo "[! !] Root login allowed via SSH. Make sure this has secure password." | tee -a "$LOG_FILE"
    else
        echo "${GREEN} [**] ${nc} Root login is disabled/restricted." | tee -a "$LOG_FILE"
    fi
fi
echo "${nc}"
    echo "--------------------------------" >> "$LOG_FILE"
    echo "      SSH section complete      " >> "$LOG_FILE"
    echo "--------------------------------" >> "$LOG_FILE"
    echo " " >> "$LOG_FILE"
sleep 2

# =============== UserID check ================

echo "[i] Starting the UserID check..." | tee -a "$LOG_FILE"
sleep 2
echo -e "\n${cyan}[*] Auditing for Unauthorized Root Privileges...${nc}"

# Look for any user with UID 0 that isn't named 'root'
EXTRA_ROOTS=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd)

if [ -n "$EXTRA_ROOTS" ]; then
    echo -e "${red}${CROSS} ALERT: This account has root-level access. Check soon!${nc}" | tee -a "$LOG_FILE"
    for user in $EXTRA_ROOTS; do
        echo -e "    [!] Potentially High Risk Account: $user" | tee -a "$LOG_FILE"
    done
else
    echo -e "${green}${CHECK} No unauthorized root accounts detected.${nc}" | tee -a "$LOG_FILE"
fi
    echo "--------------------------------" >> "$LOG_FILE"
    echo "    UserID section complete     " >> "$LOG_FILE"
    echo "--------------------------------" >> "$LOG_FILE"
    echo " " >> "$LOG_FILE"

# This is where i ran out of ideas and started asking gemini for some.
# this one i do feel is usefull because you never know who's listening to you.
#
echo -e "\n${cyan}[*] Identifying listening network services...${nc}"
# 'ss' is the modern replacement for 'netstat'
# -t (tcp) -u (udp) -l (listening) -p (process) -n (numeric)
ss -tulpn | grep LISTEN | tee -a "$LOG_FILE"

# ======================== CVE Check ===========================



# ------------------------- CVE Section Complete --------------------------------------

sleep 1
echo " Thank you for using the system auditor!"

