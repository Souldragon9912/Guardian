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
        printf "\r[%c] Checking..." "${spin:$i:1}"
        sleep 3
    done
    printf "\r[✓] Done!          \n"
    sleep 2
}

    UPTIME=$(uptime -p | sed 's/up //')
    USER_IP=$(hostname -I | awk '{print $1}')
    NODE=$(hostname)
    USER=$(whoami)

banner=$(
cat <<"EOF"
 ██████╗       ██████╗  █████╗ ███████╗███████╗██╗    ██╗██████╗
██╔════╝       ██╔══██╗██╔══██╗██╔════╝██╔════╝██║    ██║██╔══██╗
██║  ███╗█████╗██████╔╝███████║███████╗███████╗██║ █╗ ██║██║  ██║
██║   ██║╚════╝██╔═══╝ ██╔══██║╚════██║╚════██║██║███╗██║██║  ██║
╚██████╔╝      ██║     ██║  ██║███████║███████║╚███╔███╔╝██████╔╝
 ╚═════╝       ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚══╝╚══╝ ╚═════╝
EOF
)

# ====================================================================================================================================
#                                                               START OF SCRIPT
# ====================================================================================================================================

echo "${yellow}"
echo "$banner"
echo "${nc}"

echo " Welcome $USER"
    echo -e " ==================================================== "
    echo -e "  Node:    $NODE"
    echo -e "  IP:      $USER_IP"
    echo -e "  Status:  Online  |  Uptime:  $UPTIME"
    echo -e "  Version: 1.1     |  Name:    Aegis "
    echo -e " ==================================================== "
    echo "  "
echo "Welcome to G-Passwd! Here we will test your password against NIST password guidelines (SP 800-63B)"

# --- User passwd check  ---
read -sp "Please enter your password for the security audit: " user_pass
echo -e "\n\n${CYAN}--- PASSWORD SECURITY ASSESSMENT ---${NC}"

# Initialize statuses
len_stat=0; num_stat=0; up_stat=0; spec_stat=0

# --- THE COMPARISONS ---
if [ "${#user_pass}" -ge 15 ]; then
    len_stat=1
fi


if [[ "$user_pass" =~ [0-9] ]]; then
    num_stat=1
fi


if [[ "$user_pass" =~ [A-Z] ]]; then
    up_stat=1
fi


if [[ "$user_pass" =~ ['!@#$%^&*()_+.\/?<>,~`=+'] ]]; then
    spec_stat=1
fi



# --- REPORT ---
if [ "$len_stat" -eq 1 ]; then
    echo -e "$CHECK Minimum Length (15+ characters)"
else
    echo -e "$CROSS Minimum Length (15+ characters)"
fi


if [ "$num_stat" -eq 1 ]; then
    echo -e "$CHECK Contains Numbers (0-9)"
else
    echo -e "$CROSS Contains Numbers (0-9)"
fi


if [ "$up_stat" -eq 1 ]; then
    echo -e "$CHECK Contains Uppercase (A-Z)"
else
    echo -e "$CROSS Contains Uppercase (A-Z)"
fi


if [ "$spec_stat" -eq 1 ]; then
    echo -e "$CHECK Contains Special Characters (!@#$)"
else
    echo -e "$CROSS Contains Special Characters (!@#$)"
fi


# --- final check ---
SCORE=$((len_stat + num_stat + up_stat + spec_stat))

echo -e "${CYAN}------------------------------------${NC}"
if [ "$SCORE" -eq 4 ]; then
    echo -e "${CHECK} RESULT: STRONG (4/4)"
    echo "{i} PASSWD CHECK RESULT: Your password is strong enough. Keep it up! (4/4)" | tee -a Audit-log.txt
else
    echo -e "${CROSS} RESULT: WEAK ($SCORE/4)"
    echo "${red}""{!!} PASSWD CHECK RESULT: Your password did not meed one or more guidelines. Please make changes soon. ($SCORE/4)""${nc}" | tee -a Audit-log.txt
fi

