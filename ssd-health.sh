#!/usr/bin/env bash

# ssd-health-cli
# A simple CLI tool to check SSD health on Linux systems.

set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}Checking SSD Health...${NC}\n"

# Verify dependencies
if ! command -v smartctl &> /dev/null; then
    echo -e "${RED}Error: 'smartctl' is not installed.${NC}"
    echo "Please install smartmontools:"
    echo "  Ubuntu/Debian: sudo apt install smartmontools"
    echo "  Fedora/RHEL  : sudo dnf install smartmontools"
    echo "  Arch Linux   : sudo pacman -S smartmontools"
    exit 1
fi

if ! command -v lsblk &> /dev/null; then
    echo -e "${RED}Error: 'lsblk' is not installed.${NC}"
    exit 1
fi

if ! command -v awk &> /dev/null; then
    echo -e "${RED}Error: 'awk' is not installed.${NC}"
    exit 1
fi

SUDO=""
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Note: 'smartctl' requires root privileges. You may be prompted for your password.${NC}"
    if command -v sudo &> /dev/null; then
         SUDO="sudo"
    else
         echo -e "${RED}Error: Run this script as root, or install 'sudo'.${NC}"
         exit 1
    fi
fi

# Find non-rotating drives (assume SSD/NVMe)
ssds=$(lsblk -d -o NAME,ROTA | awk 'NR>1 && $2=="0" {print $1}')

if [ -z "$ssds" ]; then
    echo "No solid state drives (SSDs) found on this system."
    exit 0
fi

for disk in $ssds; do
    echo -e "Disk: ${GREEN}/dev/$disk${NC}"
    
    disk_path="/dev/$disk"
    
    # Check if disk exists
    if [ ! -b "$disk_path" ]; then
         echo -e "${RED}Error: Block device $disk_path not found.${NC}\n"
         continue
    fi

    # Get data
    info=$($SUDO smartctl -i "$disk_path" 2>/dev/null || true)
    health=$($SUDO smartctl -H "$disk_path" 2>/dev/null || true)
    attrs=$($SUDO smartctl -A "$disk_path" 2>/dev/null || true)

    # 1. Model
    model=$(echo "$info" | awk -F ': +' '/Device Model:|Model Family:|Model Number:/ {print $2; exit}')
    [ -z "$model" ] && model="Unknown Model"
    echo -e "Model: ${CYAN}$model${NC}"

    # 2. Status
    status=$(echo "$health" | awk -F ': +' '/SMART overall-health self-assessment test result/ {print $2}')
    if [ -z "$status" ]; then
        status=$(echo "$health" | awk -F ': +' '/SMART Health Status:/ {print $2}')
    fi
    [ -z "$status" ] && status="Unknown"
    
    if [[ "$status" == *"PASSED"* || "$status" == *"OK"* ]]; then
        echo -e "Status: ${GREEN}$status${NC}"
    else
        echo -e "Status: ${RED}$status${NC}"
    fi

    # 3. Health Percentage
    # Try different smartctl health indicators depending on the drive type (SATA vs NVMe)
    health_percent=""
    
    # 3a. NVMe Percentage Used
    pct_used=$(echo "$attrs" | awk -F ': +' '/Percentage Used:/ {print $2}' | tr -d '%')
    if [ -n "$pct_used" ]; then
        health_percent=$((100 - pct_used))
    fi

    # 3b. SATA Available Reserved Space (ID 232)
    if [ -z "$health_percent" ]; then
        avail_res=$(echo "$attrs" | awk '$2=="Available_Reservd_Space" {print $4}')
        if [ -n "$avail_res" ]; then
            health_percent="$avail_res"
        fi
    fi

    # 3c. SATA Wear Leveling Count (ID 177 / 173) / Media Wearout (ID 233)
    if [ -z "$health_percent" ]; then
        wear_lvl=$(echo "$attrs" | awk '$2~/Wear_Leveling_Count|Media_Wearout_Indicator/ {print $4; exit}')
        if [ -n "$wear_lvl" ]; then
            health_percent="$wear_lvl"
        fi
    fi

    if [ -n "$health_percent" ]; then
        echo -e "Health: ${CYAN}${health_percent}%${NC}"
    else
        echo -e "Health: ${YELLOW}Not Available${NC}"
    fi

    # 4. Temperature
    temp=""
    temp_nvme=$(echo "$attrs" | awk -F ': +' '/Temperature:/ {print $2}' | awk '{print $1}')
    if [ -n "$temp_nvme" ]; then
        temp="$temp_nvme"
    else
        temp_sata=$(echo "$attrs" | awk '$2=="Temperature_Celsius" {print $10}')
        if [ -n "$temp_sata" ]; then
            temp="$temp_sata"
        fi
    fi

    if [ -n "$temp" ]; then
        echo -e "Temperature: ${CYAN}${temp}°C${NC}"
    fi

    # 5. Power On Hours
    poh=""
    poh_nvme=$(echo "$attrs" | awk -F ': +' '/Power On Hours:/ {print $2}' | awk '{print $1}' | tr -d ',')
    if [ -n "$poh_nvme" ]; then
         poh="$poh_nvme"
    else
         poh_sata=$(echo "$attrs" | awk '$2=="Power_On_Hours" {print $10}')
         if [ -n "$poh_sata" ]; then
             poh="$poh_sata"
         fi
    fi
    
    if [ -n "$poh" ]; then
        echo -e "Power On Hours: ${CYAN}${poh}${NC}"
    fi

    echo ""
done
