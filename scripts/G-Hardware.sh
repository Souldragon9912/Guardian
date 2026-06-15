#!/bin/bash


# Ant2-2
# Souldragon9912


# Colors
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
nc=$(tput sgr0)

CHECK="${green}[✓]${nc}"
WARN="${yellow}[!]${nc}"
FAIL="${red}[X]${nc}"
INFO="[i]"


    UPTIME=$(uptime -p | sed 's/up //')
    USER_IP=$(hostname -I | awk '{print $1}')
    NODE=$(hostname)
    USER=$(whoami)

GUARDIAN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAIN_LOG="$GUARDIAN_ROOT/Logs/Audit-log.txt"
HW_LOG="$GUARDIAN_ROOT/Logs/hardware-log.txt"


GUARDIAN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAIN_LOG="$GUARDIAN_ROOT/Logs/Audit-log.txt"
HW_LOG="$GUARDIAN_ROOT/Logs/hardware-log.txt"

mkdir -p "$GUARDIAN_ROOT/Logs"


VM_FLAG="unknown"
ENC_FLAG="unknown"
FW_FLAG="unknown"
TPM_FLAG="unknown"
DISK_HEALTH_FLAG="unknown"
CPU_BENCH="not run"
STORAGE_BENCH="not run"
GPU_INFO="unavailable"
CPU_TEMP="unavailable"

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

# ====================================================================
#                           START OF SCRIPT
# ====================================================================


# Root check
if [ "$EUID" -ne 0 ]; then
    echo "${red}[X] This script needs to be run as root.${nc}"
    exit 1
fi

# Write a clean header to the log files instead of dumping the banner art in there
echo "Guardian Hardware Audit - $(date)" > "$MAIN_LOG" 2>/dev/null
echo "Guardian Hardware Audit - $(date)" > "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

clear
echo " "
echo " "
echo "${cyan}$banner${nc}"
echo " Welcome to Guardain Hardware Check"
    echo -e " ==================================================== "
    echo -e "  Node:    $NODE"
    echo -e "  IP:      $USER_IP"
    echo -e "  Status:  Online  |  Uptime:  $UPTIME"
    echo -e "  Version: 1.2     |  Name:    Aegis "
    echo -e " ==================================================== "
echo ""

echo "Welcome to Guardian Hardware Inspection"
echo "Here we will check your hardware and VM environment to make sure things are running properly."
echo ""

read -n 1 -s -r -p "Press any key to begin the inspection..."
echo ""
sleep 1

echo ""
echo "$INFO Starting hardware inspection..." | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

## ===== SYSTEM CONTEXT =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO System Context" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

HOSTNAME_VAL=$(hostname)
KERNEL=$(uname -r)
OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')

echo "Hostname        : $HOSTNAME_VAL" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "OS              : ${OS:-Unavailable}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Kernel          : $KERNEL" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT=$(systemd-detect-virt)
else
    VIRT="unknown"
fi

echo "Virtualization  : $VIRT" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

if [[ "$VIRT" != "none" && "$VIRT" != "unknown" ]]; then
    echo "$WARN Running in a virtualized environment" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    VM_FLAG="yes"
else
    echo "$CHECK Running on bare metal" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    VM_FLAG="no"
fi

## ===== CPU =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO CPU Information" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

if command -v lscpu >/dev/null 2>&1; then
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | sed 's/^ *//')
    CPU_CORES=$(nproc)
    CPU_ARCH=$(lscpu | grep "Architecture" | cut -d':' -f2 | sed 's/^ *//')

    echo "CPU Model       : $CPU_MODEL" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    echo "Architecture    : $CPU_ARCH" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    echo "CPU Cores       : $CPU_CORES" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

    if lscpu | grep -qiE "vmx|svm"; then
        echo "$CHECK Virtualization extensions detected (VMX/SVM)" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    else
        echo "$WARN No hardware virtualization extensions found" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    fi
else
    echo "$FAIL lscpu not found, skipping CPU section" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
fi

# CPU temperature - requires lm-sensors
if command -v sensors >/dev/null 2>&1; then
    TEMP_RAW=$(sensors 2>/dev/null | grep -iE "core 0|cpu temp|package id 0" | head -1 | grep -oE '\+[0-9]+\.[0-9]+°C' | head -1)
    if [[ -n "$TEMP_RAW" ]]; then
        CPU_TEMP="$TEMP_RAW"
        TEMP_NUM=$(echo "$TEMP_RAW" | grep -oE '[0-9]+' | head -1)
        if [[ "$TEMP_NUM" -ge 85 ]]; then
            echo "$FAIL CPU Temp: $CPU_TEMP — Critical, check your cooling" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
        elif [[ "$TEMP_NUM" -ge 70 ]]; then
            echo "$WARN CPU Temp: $CPU_TEMP — Running warm" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
        else
            echo "$CHECK CPU Temp: $CPU_TEMP — Normal" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
        fi
    else
        echo "$WARN Could not read CPU temperature" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
        CPU_TEMP="unreadable"
    fi
else
    echo "$WARN lm-sensors not installed (sudo apt install lm-sensors)" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    CPU_TEMP="lm-sensors not installed"
fi

## ===== MEMORY =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO Memory Information" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

if command -v free >/dev/null 2>&1; then
    MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
    MEM_AVAIL=$(free -h | awk '/^Mem:/ {print $7}')
    SWAP_USED=$(free -h | awk '/^Swap:/ {print $3}')

    echo "Total RAM       : $MEM_TOTAL" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    echo "Used            : $MEM_USED" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    echo "Available       : $MEM_AVAIL" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    echo "Swap Used       : $SWAP_USED" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

    # Check if swap is being used heavily which can mean RAM is running low
    SWAP_USED_KB=$(free | awk '/^Swap:/ {print $3}')
    if [[ "$SWAP_USED_KB" -gt 524288 ]]; then
        echo "$WARN High swap usage - system may be low on RAM" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    else
        echo "$CHECK Swap usage looks fine" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    fi
else
    echo "$FAIL free command not available" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
fi

## ===== STORAGE =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO Storage Devices" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

if command -v lsblk >/dev/null 2>&1; then
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE 2>/dev/null | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    echo "" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

    # Show disk usage
    echo "Disk Usage:" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    df -h 2>/dev/null | grep -v tmpfs | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

    # Check for LUKS encryption
    if lsblk -o FSTYPE 2>/dev/null | grep -qiE "crypto_LUKS|crypt"; then
        ENC_FLAG="yes"
        echo "$CHECK Encrypted storage detected (LUKS)" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    else
        ENC_FLAG="no"
        echo "$WARN No disk encryption detected" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    fi
else
    echo "$FAIL lsblk not found" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
fi

## ===== SMART HEALTH =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO SMART Drive Health" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

DISKS=$(lsblk -dno NAME 2>/dev/null | grep -E "^(nvme|sd|vd)")

if [[ -z "$DISKS" ]]; then
    echo "$WARN No physical drives found to test" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    DISK_HEALTH_FLAG="no_disks"
elif ! command -v smartctl >/dev/null 2>&1; then
    echo "$WARN smartctl not found - install smartmontools to enable drive health checks" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    echo "    sudo apt install smartmontools" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    DISK_HEALTH_FLAG="unsupported"
else
    DISK_HEALTH_FLAG="passed"
    for disk in $DISKS; do
        RESULT=$(smartctl -H "/dev/$disk" 2>/dev/null)
        if echo "$RESULT" | grep -q "PASSED"; then
            echo "$CHECK /dev/$disk - SMART health: PASSED" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
        elif echo "$RESULT" | grep -q "FAILED"; then
            echo "$FAIL /dev/$disk - SMART health: FAILED - possible drive failure!" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
            DISK_HEALTH_FLAG="failed"
        else
            echo "$WARN /dev/$disk - SMART result inconclusive (common on virtual disks)" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
        fi
    done
fi

## ===== GPU =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO GPU Information" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

if command -v lspci >/dev/null 2>&1; then
    GPU_RAW=$(lspci 2>/dev/null | grep -iE "VGA|3D|Display")
    if [[ -n "$GPU_RAW" ]]; then
        GPU_INFO=$(echo "$GPU_RAW" | sed 's/.*: //')
        echo "GPU             : $GPU_INFO" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

        # If nvidia-smi is available we can get more detail like temps and VRAM
        if command -v nvidia-smi >/dev/null 2>&1; then
            NVIDIA_INFO=$(nvidia-smi --query-gpu=name,memory.total,temperature.gpu,driver_version --format=csv,noheader 2>/dev/null)
            if [[ -n "$NVIDIA_INFO" ]]; then
                echo "NVIDIA Details  : $NVIDIA_INFO" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
            fi
        fi
    else
        GPU_INFO="none detected"
        echo "$WARN No GPU detected via lspci" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    fi
else
    echo "$WARN lspci not found - skipping GPU check" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    GPU_INFO="lspci unavailable"
fi

## ===== NETWORK =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO Network Interfaces" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

if command -v ip >/dev/null 2>&1; then
    ip -brief link 2>/dev/null | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
else
    echo "$FAIL ip command not found" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
fi

## ===== FIRMWARE =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO Firmware Information" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

BIOS_VENDOR=$(cat /sys/class/dmi/id/bios_vendor 2>/dev/null)
BIOS_VERSION=$(cat /sys/class/dmi/id/bios_version 2>/dev/null)

echo "BIOS Vendor     : ${BIOS_VENDOR:-Unavailable}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "BIOS Version    : ${BIOS_VERSION:-Unavailable}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

if [[ -d /sys/firmware/efi ]]; then
    FW_FLAG="uefi"
    echo "$CHECK UEFI detected" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
else
    FW_FLAG="bios"
    echo "$WARN Legacy BIOS detected - UEFI is recommended for better security" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
fi

## ===== TPM =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO TPM (Trusted Platform Module)" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

# Check for a TPM chip - it shows up as a device file if present
if [[ -e /dev/tpm0 || -e /dev/tpmrm0 ]]; then
    TPM_FLAG="present"
    echo "$CHECK TPM chip detected" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
elif [[ -d /sys/class/tpm ]] && [[ -n "$(ls /sys/class/tpm/ 2>/dev/null)" ]]; then
    TPM_FLAG="present"
    echo "$CHECK TPM detected" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
else
    TPM_FLAG="missing"
    echo "$WARN No TPM chip detected" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
fi

## ===== BENCHMARKS =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO Hardware Benchmarks" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

# CPU benchmark using sysbench
if command -v sysbench >/dev/null 2>&1; then
    echo "$INFO Running CPU benchmark (5 seconds)..."
    cpu_score=$(sysbench cpu --cpu-max-prime=10000 --time=5 run 2>/dev/null | grep "events per second:" | awk '{print $4}')
    CPU_BENCH="${cpu_score} events/sec"
    echo "$CHECK CPU Benchmark    : $CPU_BENCH" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
else
    CPU_BENCH="sysbench not installed"
    echo "$WARN CPU Benchmark    : $CPU_BENCH" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
    echo "    Install with: sudo apt install sysbench" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
fi

# Storage write speed test - writes a temp file to /tmp and cleans it up
echo "$INFO Running storage write benchmark (512MB)..."
BENCH_TMP="/tmp/guardian_bench_$$"
write_speed=$(dd if=/dev/zero of="$BENCH_TMP" bs=1M count=512 conv=fdatasync 2>&1 | grep -oE '[0-9.]+ [KMGT]?B/s' | tail -1)
rm -f "$BENCH_TMP"
STORAGE_BENCH="${write_speed:-measurement failed}"
echo "$CHECK Storage Speed   : $STORAGE_BENCH" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

## ===== SECURITY OBSERVATIONS =====
echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "$INFO Security Observations" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

[[ "$VM_FLAG" == "yes" ]]                  && echo "$WARN Running in VM environment" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
[[ "$ENC_FLAG" == "no" ]]                  && echo "$WARN No disk encryption detected" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
[[ "$FW_FLAG" == "bios" ]]                 && echo "$WARN Legacy BIOS reduces security posture" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
[[ "$TPM_FLAG" == "missing" ]]             && echo "$WARN No TPM chip - hardware key storage unavailable" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
[[ "$DISK_HEALTH_FLAG" == "failed" ]]      && echo "$FAIL CRITICAL: Drive failure detected - back up your data now!" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
[[ "$DISK_HEALTH_FLAG" == "unsupported" ]] && echo "$WARN Install smartmontools for drive health checks" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

# ====================================================================
#                           END OF SCRIPT
# ====================================================================

sleep 2
clear
echo ""
echo "${cyan}$banner${nc}"

echo -e "\n----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "${green}SYSTEM SUMMARY${nc}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "----------------------------------------" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

echo "Hostname        : $HOSTNAME_VAL" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Virtualized     : $VIRT" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Firmware        : ${FW_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Disk Encryption : ${ENC_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "TPM Chip        : ${TPM_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Drive Health    : ${DISK_HEALTH_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "CPU Temp        : $CPU_TEMP" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "GPU             : $GPU_INFO" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "CPU Benchmark   : $CPU_BENCH" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Storage Speed   : $STORAGE_BENCH" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Full log saved to: $HW_LOG" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null



echo "
Thank you for using Guardian Hardware!
"

echo "Hostname        : $HOSTNAME_VAL" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Virtualized     : $VIRT" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Firmware        : ${FW_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Disk Encryption : ${ENC_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "TPM Chip        : ${TPM_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Drive Health    : ${DISK_HEALTH_FLAG^^}" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "CPU Temp        : $CPU_TEMP" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "GPU             : $GPU_INFO" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "CPU Benchmark   : $CPU_BENCH" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Storage Speed   : $STORAGE_BENCH" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null
echo "Full log saved to: $HW_LOG" | tee -a "$MAIN_LOG" "$HW_LOG" 2>/dev/null

exit 0
