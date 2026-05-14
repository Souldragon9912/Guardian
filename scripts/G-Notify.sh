#!/bin/bash

# --- Guardian Sentinel: Notification Setup Wizard ---

AUDIT_SCRIPT="/home/brendan/guardian/scripts/g-vault-audit.sh"
MSMTP_CONF="$HOME/.msmtprc"

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
echo "  "
echo "${blue}"
echo "$banner"
echo "${nc}"
    # --- 3. System Stats ---
    echo -e "\e[1;30m====================================================\e[0m"
    echo -e " \e[1;37mNode:\e[0m   $NODE"
    echo -e " \e[1;37mIP:\e[0m     $USER_IP"
    echo -e " \e[1;37mStatus:\e[0m Online  |  \e[1;37mUptime:\e[0m $UPTIME"
    echo -e "\e[1;30m====================================================\e[0m"
    echo ""

# ---------------------------------------------------------
# STEP 1: Phone Number & Gateway Construction
# ---------------------------------------------------------
echo "[*] Step 1: Destination Setup"
read -p "Enter the 10-digit target phone number (no dashes/spaces): " PHONE_NUM

# Simple regex validation to ensure they typed exactly 10 digits
if ! [[ "$PHONE_NUM" =~ ^[0-9]{10}$ ]]; then
    echo "[!] ERROR: Invalid format. Must be exactly 10 digits."
    exit 1
fi

echo ""
echo "[*] Select the cellular provider for $PHONE_NUM:"
# Using fzf to create the interactive "database" menu
PROVIDER=$(echo -e "Verizon\nAT&T\nT-Mobile\nSprint\nGoogle Fi\nBoost Mobile\nCricket Wireless\nUS Cellular" | fzf \
    --header="[ Select Target Carrier ]" --reverse --height=30% --prompt="Provider > ")

# Mapping the selection to the correct gateway domain
case "$PROVIDER" in
    "Verizon")          GATEWAY="@vtext.com" ;;
    "AT&T")             GATEWAY="@txt.att.net" ;;
    "T-Mobile")         GATEWAY="@tmomail.net" ;;
    "Sprint")           GATEWAY="@messaging.sprintpcs.com" ;;
    "Google Fi")        GATEWAY="@msg.fi.google.com" ;;
    "Boost Mobile")     GATEWAY="@sms.myboostmobile.com" ;;
    "Cricket Wireless") GATEWAY="@mms.cricketwireless.net" ;;
    "US Cellular")      GATEWAY="@email.uscc.net" ;;
    *) echo "[!] Configuration aborted."; exit 1 ;;
esac

# Stitching it together
FULL_TARGET="${PHONE_NUM}${GATEWAY}"
echo "[+] Constructed Target Address: $FULL_TARGET"

# Injecting the new target into the audit script
sed -i "s|^ALERT_PHONE=.*|ALERT_PHONE=\"$FULL_TARGET\"|" "$AUDIT_SCRIPT"
echo "[+] Guardian Audit Script updated successfully."
echo ""

# ---------------------------------------------------------
# STEP 2: Service Account Generation (msmtp)
# ---------------------------------------------------------
echo "[*] Step 2: Service Account Authorization"
echo "Do you want to configure the Guardian outbound service account?"
read -p "(y/n) > " SETUP_ACCOUNT

if [[ "$SETUP_ACCOUNT" == "y" || "$SETUP_ACCOUNT" == "Y" ]]; then
    echo ""
    read -p "Enter the Guardian Gmail Address: " SENDER_EMAIL
    read -s -p "Enter the 16-character App Password: " SENDER_PASS
    echo ""

    # Generating the ~/.msmtprc file dynamically
    cat <<EOF > "$MSMTP_CONF"
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        guardian
host           smtp.gmail.com
port           587
from           $SENDER_EMAIL
user           $SENDER_EMAIL
password       $SENDER_PASS

account default : guardian
EOF

    # Locking down the permissions
    chmod 600 "$MSMTP_CONF"
    echo "[+] Outbound mail relay (msmtp) configured and secured."
else
    echo "[*] Skipping service account setup."
fi

# ---------------------------------------------------------
# STEP 3: Test Fire
# ---------------------------------------------------------
echo ""
echo "====================================================="
echo "[+] Setup Complete. G-Vault is fully armed."
read -p "Would you like to send a test ping to $FULL_TARGET now? (y/n) > " TEST_PING

if [[ "$TEST_PING" == "y" || "$TEST_PING" == "Y" ]]; then
    echo "[*] Firing test payload..."
    PAYLOAD="🛡️ [ STH GUARDIAN ]\nNotification system is online and routing correctly."
    echo -e "From: Guardian Framework <guardian@localhost>\nSubject: GUARDIAN PING\n\n$PAYLOAD" | msmtp -a guardian "$FULL_TARGET"
    echo "[+] Packet sent."
fi
