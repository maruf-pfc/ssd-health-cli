#!/usr/bin/env bash

# disk-health-cli
# A clean CLI tool to check SATA SSD, NVMe, HDD, and RAID health on Linux.

set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}Checking Disk Health...${NC}\n"

# Verify/Install dependencies
MISSING_DEPS=0
SUDO=""
if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
         SUDO="sudo"
    else
         echo -e "${RED}Error: Run this script as root, or install 'sudo'.${NC}"
         exit 1
    fi
fi

if ! command -v smartctl &> /dev/null; then
    echo -e "${YELLOW}Warning: 'smartctl' is not installed.${NC}"
    MISSING_DEPS=1
fi
if ! command -v lsblk &> /dev/null; then
    echo -e "${YELLOW}Warning: 'lsblk' is not installed.${NC}"
    MISSING_DEPS=1
fi
if ! command -v awk &> /dev/null; then
    echo -e "${YELLOW}Warning: 'awk' is not installed.${NC}"
    MISSING_DEPS=1
fi

if [ $MISSING_DEPS -eq 1 ]; then
    echo -e "${YELLOW}Attempting to install missing dependencies...${NC}"
    if command -v apt &> /dev/null; then
        $SUDO apt update && $SUDO apt install -y smartmontools gawk util-linux nvme-cli || true
    elif command -v dnf &> /dev/null; then
        $SUDO dnf install -y smartmontools gawk util-linux nvme-cli || true
    elif command -v pacman &> /dev/null; then
        $SUDO pacman -Sy --noconfirm smartmontools gawk util-linux nvme-cli || true
    else
        echo -e "${RED}Error: Could not automatically install dependencies. Please install smartmontools physically.${NC}"
        exit 1
    fi
fi

# Function to convert hours to Days, Hours, Minutes
format_hours() {
    local total_hours=$1
    if [ -z "$total_hours" ] || ! [[ "$total_hours" =~ ^[0-9]+$ ]]; then
        echo "Not Available"
        return
    fi
    local days=$((total_hours / 24))
    local hours=$((total_hours % 24))
    echo "${days} days ${hours} hours 0 minutes" # Minute granularity not typically exposed simply via smartctl Power_On_Hours, defaulting to 0
}

# Find all physical disks (exclude partitions, loopbacks, ram/zram)
disks=$(lsblk -d -n -o NAME,TYPE,ROTA | awk '$2=="disk" && $1!~/^zram/ && $1!~/^loop/ && $1!~/^ram/ {print $1","$3}')

if [ -z "$disks" ]; then
    echo "No physical disks found on this system."
    exit 0
fi

for disk_info in $disks; do
    disk=$(echo "$disk_info" | cut -d',' -f1)
    rota=$(echo "$disk_info" | cut -d',' -f2)
    disk_path="/dev/$disk"
    
    if [ ! -b "$disk_path" ]; then
         continue
    fi

    # Determine drive type
    drive_type="Unknown"
    if [[ "$disk" == nvme* ]]; then
        drive_type="NVMe SSD"
    elif [ "$rota" == "0" ]; then
        drive_type="SATA SSD"
    else
        drive_type="HDD"
    fi

    # Fetch SMART data
    info=$($SUDO smartctl -i "$disk_path" 2>/dev/null || true)
    health=$($SUDO smartctl -H "$disk_path" 2>/dev/null || true)
    attrs=$($SUDO smartctl -A "$disk_path" 2>/dev/null || true)
    nvme_smart=$($SUDO nvme smart-log "$disk_path" 2>/dev/null || true)

    # Output block header
    echo "------------------------------------"
    echo -e "Disk: ${GREEN}$disk_path${NC}"
    
    # 1. Model & Device Info
    model=$(echo "$info" | awk -F ': +' '/Device Model:|Model Family:|Model Number:/ {print $2; exit}')
    [ -z "$model" ] && model="Unknown Model"
    echo "Model: $model"
    
    serial=$(echo "$info" | awk -F ': +' '/Serial Number:/ {print $2; exit}')
    [ -n "$serial" ] && echo "Serial Number: $serial"
    
    firmware=$(echo "$info" | awk -F ': +' '/Firmware Version:/ {print $2; exit}')
    [ -n "$firmware" ] && echo "Firmware: $firmware"

    echo "Type: $drive_type"

    capacity=$(lsblk -d -n -h -o SIZE "$disk_path" | awk 'NR==1{print $1}')
    [ -n "$capacity" ] && echo "Capacity: $capacity"
    
    # 2. Status
    status=$(echo "$health" | awk -F ': +' '/SMART overall-health self-assessment test result/ {print $2}')
    if [ -z "$status" ]; then
        status=$(echo "$health" | awk -F ': +' '/SMART Health Status:/ {print $2}')
    fi
    [ -z "$status" ] && status="Unknown"
    
    if [[ "$status" == *"PASSED"* || "$status" == *"OK"* ]]; then
        echo -e "Status: ${GREEN}PASSED${NC}"
    else
        echo -e "Status: ${RED}$status${NC}"
    fi

    # 3. Health & Specific Metrics
    health_percent=""
    temp=""
    poh=""
    data_written=""
    
    if [ "$drive_type" == "NVMe SSD" ]; then
        # Use nvme-cli if available, fallback to smartctl
        pct_used=$(echo "$nvme_smart" | awk -F ': ' '/percentage_used/ {print $2}' | tr -d '%')
        if [ -n "$pct_used" ]; then
            health_percent=$((100 - pct_used))
        else
            pct_used=$(echo "$attrs" | awk -F ': +' '/Percentage Used:/ {print $2}' | tr -d '%')
            [ -n "$pct_used" ] && health_percent=$((100 - pct_used))
        fi

        # Match only the exact 'temperature' field — NOT 'temperature_sensor_1', 'temperature_sensor_2', etc.
        temp_raw=$(echo "$nvme_smart" | awk -F ': ' '/^temperature[[:space:]]/ {print $2; exit}' | awk '{print $1}')
        # The NVMe spec stores temperature in Kelvin; some nvme-cli versions output the raw Kelvin
        # value without converting to Celsius. Threshold of 200 is safe: no real NVMe operates at 200°C,
        # but any Kelvin value for a plausible operating temperature will always be > 200 (273 K = 0°C).
        if [[ "$temp_raw" =~ ^[0-9]+$ ]]; then
            if [ "$temp_raw" -gt 200 ]; then
                temp=$((temp_raw - 273))
            else
                temp="$temp_raw"
            fi
        fi
        # Fallback: smartctl -A; use 'exit' to stop after the first match and avoid multiline capture
        [ -z "$temp" ] && temp=$(echo "$attrs" | awk -F ': +' '/Temperature:/ {print $2; exit}' | awk '{print $1}')
        
        poh_raw=$(echo "$nvme_smart" | awk -F ': ' '/power_on_hours/ {print $2}' | tr -d ',')
        [ -z "$poh_raw" ] && poh_raw=$(echo "$attrs" | awk -F ': +' '/Power On Hours:/ {print $2}' | awk '{print $1}' | tr -d ',')
        poh=$(format_hours "$poh_raw")

        data_written_units=$(echo "$nvme_smart" | awk -F ': ' '/data_units_written/ {print $2}' | awk '{print $1}' | tr -d ',')
        if [ -n "$data_written_units" ] && [[ "$data_written_units" =~ ^[0-9]+$ ]]; then
            # NVMe units are in thousands of 512 byte sectors (so x 512,000 for exact bytes)
            tbw="$(awk -v dw="$data_written_units" 'BEGIN { printf "%.2f", (dw * 512000) / (1024*1024*1024*1024) }')"
            data_written="${tbw} TB"
        fi
        
    elif [ "$drive_type" == "SATA SSD" ]; then
        avail_res=$(echo "$attrs" | awk '$2=="Available_Reservd_Space" {print $4}')
        [ -n "$avail_res" ] && health_percent="$avail_res"
        [ -z "$health_percent" ] && health_percent=$(echo "$attrs" | awk '$2~/Wear_Leveling_Count|Media_Wearout_Indicator/ {print $4; exit}')

        temp=$(echo "$attrs" | awk '$2=="Temperature_Celsius" {print $10}')
        poh_raw=$(echo "$attrs" | awk '$2=="Power_On_Hours" {print $10}')
        poh=$(format_hours "$poh_raw")
        
        # Extrapolate TBW from Total_LBAs_Written if available (512 bytes per LBA approximation)
        lbas=$(echo "$attrs" | awk '$2=="Total_LBAs_Written" {print $10}')
        if [ -n "$lbas" ] && [[ "$lbas" =~ ^[0-9]+$ ]]; then
            tbw="$(awk -v lbas="$lbas" 'BEGIN { printf "%.2f", (lbas * 512) / (1024*1024*1024*1024) }')"
            data_written="${tbw} TB"
        fi
        
    elif [ "$drive_type" == "HDD" ]; then
        # HDDs don't have a single "health percentage", typically use Reallocated Sectors as primary failing indicator
        realloc=$(echo "$attrs" | awk '$2=="Reallocated_Sector_Ct" {print $10}')
        
        temp=$(echo "$attrs" | awk '$2=="Temperature_Celsius" {print $10}')
        poh_raw=$(echo "$attrs" | awk '$2=="Power_On_Hours" {print $10}')
        poh=$(format_hours "$poh_raw")
    fi

    # Display Parsed Metrics
    if [ -n "$health_percent" ] && [[ "$health_percent" =~ ^[0-9]+$ ]]; then
        echo -e "Health: ${CYAN}${health_percent}%${NC}"
    elif [ "$drive_type" == "HDD" ] && [ -n "$realloc" ]; then
        if [ "$realloc" -gt 0 ]; then
            echo -e "Reallocated Sectors: ${RED}${realloc} (Warning!)${NC}"
        else
            echo "Reallocated Sectors: 0 (Healthy)"
        fi
    fi

    if [ -n "$temp" ] && [[ "$temp" =~ ^[0-9]+$ ]]; then
        echo "Temperature: ${temp}°C"
    fi

    if [ -n "$poh" ]; then
        echo "Power On Time: ${poh}"
    fi

    if [ -n "$data_written" ]; then
        echo "Data Written: ${data_written}"
    fi
done
echo "------------------------------------"
