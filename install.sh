#!/usr/bin/env bash

# Installer for ssd-health-cli
# Copies the script to /usr/local/bin so it can be run globally

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Installing ssd-health-cli...${NC}"

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run the installer as root (e.g., sudo ./install.sh)${NC}"
    exit 1
fi

if [ ! -f "ssd-health.sh" ]; then
    echo -e "${RED}Error: ssd-health.sh not found in the current directory.${NC}"
    exit 1
fi

# Install to /usr/local/bin
TARGET="/usr/local/bin/ssd-health"

echo "Copying ssd-health.sh to $TARGET..."
cp ssd-health.sh "$TARGET"
chmod +x "$TARGET"

echo -e "${GREEN}Installation successful!${NC}"
echo -e "You can now run '${CYAN}ssd-health${NC}' from anywhere."
