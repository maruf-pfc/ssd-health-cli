<h1 align="center">SSD Health CLI</h1>

<p align="center">
  <strong>A simple, professional Linux command-line tool to check your SSD's health.</strong>
</p>

<p align="center">
  <img alt="License: GNU GENERAL PUBLIC LICENSE" src="https://img.shields.io/badge/License-GNU%20GENERAL%20PUBLIC%20LICENSE-blue.svg" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-Linux-lightgrey.svg" />
  <img alt="Bash" src="https://img.shields.io/badge/language-Bash-4EAA25.svg" />
</p>

---

## 📌 Description

`ssd-health-cli` is a minimal, beautifully formatted CLI tool designed specifically for Linux. It quickly scans all Solid State Drives (NVMe and SATA) on your system and presents their critical S.M.A.R.T. health attributes, including:
- **Device Model**
- **Overall Health Status**
- **Health Percentage Remaining**
- **Operating Temperature**
- **Power On Hours**

By leveraging `smartctl` under the hood, it eliminates the need to parse through long wall-of-text reports, giving you exactly the details you need at a glance.

## 🚀 Features

- **Automated Detection**: Auto-detects all solid state non-rotating drives attached to the system.
- **Support for Both NVMe & SATA**: Intelligently handles different SMART attribute layouts.
- **Clean Output**: Displays results plainly with helpful terminal colors.
- **Quick Installation**: Globally installable with an included script.

## 📋 Prerequisites

This tool relies on `smartmontools` and standard Linux utilities (`awk`, `lsblk`).
If `smartctl` is not installed, install it via your distribution's package manager:

**Ubuntu / Debian:**
```bash
sudo apt update
sudo apt install smartmontools
```

**Fedora / RHEL:**
```bash
sudo dnf install smartmontools
```

**Arch Linux:**
```bash
sudo pacman -S smartmontools
```

## 🛠️ Installation

### Option 1: One-Line Installer (Recommended)
You can install `ssd-health-cli` directly by running the following command in your terminal:
```bash
curl -sSfL https://raw.githubusercontent.com/blackstart-labs/ssd-health-cli/main/install.sh | sudo bash
```

### Option 2: Manual Installation (Git Clone)
Clone the repository and run the installer script.

```bash
git clone https://github.com/blackstart-labs/ssd-health-cli.git
cd ssd-health-cli

# Make scripts executable
chmod +x ssd-health.sh install.sh

# Run the installer script with root privileges
sudo ./install.sh
```

## 💡 Usage

After installation, the tool is available globally! Run the command:

```bash
sudo ssd-health
```

_Note: The tool requires root privileges to read SMART data directly from your hardware._

### Example Output

```text
Checking SSD Health...

Disk: /dev/nvme0n1
Model: Generic Ultra-Fast NVMe 1TB
Status: PASSED
Health: 100%
Temperature: 48°C
Power On Hours: 13703

Disk: /dev/sdb
Model: Samsung SSD 850 EVO 500GB
Status: PASSED
Health: 98%
Temperature: 33°C
Power On Hours: 5204
```

## 📄 License

This project is licensed under the [GNU GENERAL PUBLIC LICENSE](LICENSE). Feel free to contribute, modify, and distribute it!
