#!/bin/bash
# Guardian Module: G-Hardware

# Colors
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
nc=$(tput sgr0)

CHECK="${green}[✓]${nc}"
WARN="${yellow}[!]${nc}"
FAIL="${red}[X]${nc}"
INFO="[i]"

MAIN_LOG="$HOME/Guardian/Logs/Audit-log.txt"
HW_LOG="$HOME/Guardian/Logs/hardware-log.txt"

## Safe defaults
VM_FLAG="unknown"
ENC_FLAG="unknown"
FW_FLAG="unknown"

## ===== Banner =====
banner=$(
cat << "EOF"
 ██████╗       ██╗  ██╗ █████╗ ██████╗ ██████╗ ██╗    ██╗ █████╗ ██████╗ ███████╗
██╔════╝       ██║  ██║██╔══██╗██╔══██╗██╔══██╗██║    ██║██╔══██╗██╔══██╗██╔════╝
██║  ███╗█████╗███████║███████║██████╔╝██║  ██║██║ █╗ ██║███████║██████╔╝█████╗
██║   ██║╚════╝██╔══██║██╔══██║██╔══██╗██║  ██║██║███╗██║██╔══██║██╔══██╗██╔══╝
╚██████╔╝      ██║  ██║██║  ██║██║  ██║██████╔╝╚███╔███╔╝██║  ██║██║  ██║███████╗
 ╚═════╝       ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
EOF
)
# Souldragon912
# Ant2-2

# ====================================================================================================================================
#                                                               START OF SCRIPT
# ====================================================================================================================================

# ROOT CHECK
if [ "$EUID" -ne 0 ]; then
  whiptail --title "Error" --msgbox "In order for the audit to continue, this must be run as root." 8 45
  exit 1
fi

clear
echo ""
echo ""
echo "$banner" | tee "$MAIN_LOG" "$HW_LOG"
echo "welcome to Guardian Hardare inspection
Here we will test for a few things to make sure your hardare or VM are working properly"

read -n 1 -s -r -p "Press any key to begin the test..."
sleep 2

echo "$INFO Starting hardware inspection..." | tee -a "$MAIN_LOG" "$HW_LOG"
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"

## ===== SYSTEM CONTEXT =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "$INFO System Context" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"

echo "$INFO Collecting system info..." | tee -a "$MAIN_LOG" "$HW_LOG"

HOSTNAME=$(hostname)

if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT=$(systemd-detect-virt)
else
    VIRT="unknown"
fi

echo "Hostname        : $HOSTNAME" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "Virtualization  : $VIRT" | tee -a "$MAIN_LOG" "$HW_LOG"

if [[ "$VIRT" != "none" && "$VIRT" != "unknown" ]]; then
    echo "$WARN Running in virtualized environment" | tee -a "$MAIN_LOG" "$HW_LOG"
    VM_FLAG="yes"
else
    echo "$CHECK Running on bare metal" | tee -a "$MAIN_LOG" "$HW_LOG"
    VM_FLAG="no"
fi

## ===== CPU =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "$INFO CPU Information" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"

if command -v lscpu >/dev-null 2>&1; then
    echo "$INFO Collecting CPU info..." | tee -a "$MAIN_LOG" "$HW_LOG"

    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | sed 's/^ *//')
    CPU_CORES=$(nproc)

    echo "CPU Model       : $CPU_MODEL" | tee -a "$MAIN_LOG" "$HW_LOG"
    echo "CPU Cores       : $CPU_CORES" | tee -a "$MAIN_LOG" "$HW_LOG"

    if lscpu | grep -qE "vmx|svm"; then
        echo "$CHECK Virtualization support detected" | tee -a "$MAIN_LOG" "$HW_LOG"
    else
        echo "$WARN No virtualization extensions detected" | tee -a "$MAIN_LOG" "$HW_LOG"
    fi
else
    echo "$FAIL lscpu not found, skipping CPU" | tee -a "$MAIN_LOG" "$HW_LOG"
fi

## ===== MEMORY =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "$INFO Memory Information" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"

if command -v free >/dev/null 2>&1; then
    free -h | tee -a "$MAIN_LOG" "$HW_LOG"
else
    echo "$FAIL free command not available" | tee -a "$MAIN_LOG" "$HW_LOG"
fi

## ===== STORAGE =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "$INFO Storage Devices" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"

if command -v lsblk >/dev/null 2>&1; then
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE | tee -a "$MAIN_LOG" "$HW_LOG"

    if lsblk -o FSTYPE | grep -qiE "crypt|luks"; then
        ENC_FLAG="yes"
        echo "$CHECK Encrypted storage detected" | tee -a "$MAIN_LOG" "$HW_LOG"
    else
        ENC_FLAG="no"
        echo "$WARN No disk encryption detected" | tee -a "$MAIN_LOG" "$HW_LOG"
    fi
else
    echo "$FAIL lsblk not found" | tee -a "$MAIN_LOG" "$HW_LOG"
fi

echo "------- SMART test -------"
# B.E.
echo -e "\n[*] Auditing Physical Storage Media Health (SMART)..." | tee -a "$MAIN_LOG" "$HW_LOG"

# Loop through primary nvme or sd disk blocks (excluding partition slices like nvme0n1p1)
for disk in $(lsblk -dno NAME | grep -E 'nvme|sd'); do
    if command -v smartctl &> /dev/null; then
        # Check overall health status using standard smartctl evaluation
        if sudo smartctl -H "/dev/$disk" | grep -q "PASSED"; then
            echo "$CHECK Drive /dev/$disk physical health: PASSED" | tee -a "$MAIN_LOG" "$HW_LOG"
            DISK_HEALTH_FLAG="passed"
        else
            echo "$FAIL Drive /dev/$disk reporting physical hardware degradation!" | tee -a "$MAIN_LOG" "$HW_LOG"
            DISK_HEALTH_FLAG="failed"
        fi
    else
        echo "$WARN smartctl utility missing. Cannot poll hardware diagnostics." | tee -a "$MAIN_LOG" "$HW_LOG"
        DISK_HEALTH_FLAG="unsupported"
        break
    fi
done
# B.E.

## ===== HARDWARE BENCHMARKING =====
echo -e "\n[*] Running Background Hardware Benchmarks..." >> "$HW_LOG"

# A. CPU Integer Math Performance Test
if command -v sysbench &> /dev/null; then
    echo "  -> Processing CPU Prime Stress Test (Single-Thread)..." >> "$HW_LOG"
    # Runs a quick 5-second calculation check up to 10,000 primes
    cpu_score=$(sysbench cpu --cpu-max-prime=10000 --time=5 run | grep "events per second:" | awk '{print $4}')
    CPU_BENCH="${cpu_score} eps (events per-second)"
else
    CPU_BENCH="Unsupported (Install sysbench)"
fi

# B. Storage Drive Write Speed Test
echo "  -> Processing Storage Write Performance Test..." >> "$HW_LOG"
# Safely writes a temporary 512MB file to check raw throughput, then cleans up
if command -v dd &> /dev/null; then
    write_speed=$(dd if=/dev/zero of=./.bench_tmp bs=1M count=512 conv=fdatasync 2>&1 | grep -oE '[0-9.]+ [KMGT]?B/s')
    rm -f ./.bench_tmp
    STORAGE_BENCH="$write_speed"
else
    STORAGE_BENCH="Unknown"
fi

## ===== NETWORK =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "$INFO Network Interfaces" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"

if command -v ip >/dev/null 2>&1; then
    ip -brief link | tee -a "$MAIN_LOG" "$HW_LOG"
else
    echo "$FAIL ip command not found" | tee -a "$MAIN_LOG" "$HW_LOG"
fi

## ===== FIRMWARE =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "$INFO Firmware Information" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"

BIOS_VENDOR=$(cat /sys/class/dmi/id/bios_vendor 2>/dev/null)
BIOS_VERSION=$(cat /sys/class/dmi/id/bios_version 2>/dev/null)

echo "BIOS Vendor     : ${BIOS_VENDOR:-Unavailable}" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "BIOS Version    : ${BIOS_VERSION:-Unavailable}" | tee -a "$MAIN_LOG" "$HW_LOG"

if [[ -d /sys/firmware/efi ]]; then
    FW_FLAG="uefi"
    echo "$CHECK UEFI detected" | tee -a "$MAIN_LOG" "$HW_LOG"
else
    FW_FLAG="bios"
    echo "$WARN Legacy BIOS mode detected" | tee -a "$MAIN_LOG" "$HW_LOG"
fi


## ===== SECURITY OBSERVATIONS =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "$INFO Security Observations" | tee -a "$MAIN_LOG" "$HW_LOG"

echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"

[[ "$VM_FLAG" == "yes" ]] && echo "$WARN Running in VM environment" | tee -a "$MAIN_LOG" "$HW_LOG"
[[ "$ENC_FLAG" == "no" ]] && echo "$WARN No disk encryption detected" | tee -a "$MAIN_LOG" "$HW_LOG"
[[ "$FW_FLAG" == "bios" ]] && echo "$WARN Legacy BIOS mode reduces security thresholds" | tee -a "$MAIN_LOG" "$HW_LOG"
[[ "$TPM_FLAG" == "missing" ]] && echo "$WARN Missing TPM chip limits hardware cryptographic binding" | tee -a "$MAIN_LOG" "$HW_LOG"
[[ "$DISK_HEALTH_FLAG" == "failed" ]] && echo "$FAIL CRITICAL: Physical storage hardware failure imminent!" | tee -a "$MAIN_LOG" "$HW_LOG"
[[ "$DISK_HEALTH_FLAG" == "unsupported" ]] && echo "$WARN Install smartmontools package for deep media auditing" | tee -a "$MAIN_LOG" "$HW_LOG"

# ================ End Of Script =================

sleep 2
clear
echo ""
echo ""
echo "$banner"

## ===== SUMMARY =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "${green}SYSTEM SUMMARY${nc}" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG"

echo "Virtualized      : ${VIRT:-Unknown}" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "Disk Encryption  : ${ENC_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "Firmware Mode    : ${FW_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "TPM Hardware     : ${TPM_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "Storage Health   : ${DISK_HEALTH_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "CPU Benchmark    : $CPU_BENCH" | tee -a "$MAIN_LOG" "$HW_LOG"
echo "Storage Speed    : $STORAGE_BENCH" | tee -a "$MAIN_LOG" "$HW_LOG"
exit 0
