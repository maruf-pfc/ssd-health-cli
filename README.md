<h1 align="center">Disk Health CLI</h1>

<p align="center">
  <strong>A powerful Linux command-line tool to check the health of all your storage devices.</strong>
</p>

<p align="center">
  <img alt="License: Apache License" src="https://img.shields.io/badge/License-Apache%20License-blue.svg" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-Linux-lightgrey.svg" />
  <img alt="Bash" src="https://img.shields.io/badge/language-Bash-4EAA25.svg" />
</p>

---

## 📌 Description

`disk-health-cli` is a clean, minimal CLI tool designed specifically for Linux that detects and analyzes storage devices to present their health information in a readable format.

Instead of parsing through raw S.M.A.R.T. output walls of text, it neatly summarizes:
- **Device Information** (Path, Model, Serial Number, Firmware, Capacity)
- **Health Information** (SMART Status, Percentage Health, Operating Temperature)
- **Power On Time** (Cleanly formatted into Days, Hours, Minutes)
- **Specialized Metrics** (Such as Total Data Written for SSDs/NVMe, or Reallocated Sectors for HDDs)

Whether you are using an **HDD**, **SATA SSD**, **NVMe Drive**, or hardware **RAID array** with SMART data available, `disk-health-cli` will accurately present the critical metrics.

## 🚀 Features

- **Broad Hardware Support**: Intelligently handles NVMe, SATA SSDs, and Traditional HDDs.
- **Automated Detection**: Auto-detects all physical disks attached to the system (excluding loopbacks or virtual ramdrives).
- **Auto-Installation of Dependencies**: Seamlessly installs `smartmontools` and `nvme-cli` if they are missing using `apt`, `dnf`, or `pacman`.
- **Self-Updating**: Keep your script instantly up to date with the newest features using the `--update` flag.
- **Clean Output**: Displays results plainly with helpful terminal colors in a structured block format.

## 📋 Dependencies

The script will attempt to install these automatically via your system package manager if they are missing.
- `smartmontools`
- `nvme-cli`
- `gawk`
- `util-linux` (`lsblk`)

## 🛠️ Installation

### Option 1: One-Line Installer (Recommended)
You can install `disk-health-cli` directly by running the following command in your terminal:
```bash
curl -sSfL https://raw.githubusercontent.com/blackstart-labs/disk-health-cli/main/install.sh | sudo bash
```

### Option 2: Manual Installation (Git Clone)
Clone the repository and run the installer script.

```bash
git clone https://github.com/blackstart-labs/disk-health-cli.git
cd disk-health-cli

# Make scripts executable
chmod +x disk-health.sh install.sh

# Run the installer script with root privileges
sudo ./install.sh
```

## 💡 Usage

After installation, the tool is available globally! Run the command:

```bash
sudo disk-health
```

_Note: The tool requires root privileges to read SMART data directly from your hardware._

### Checking for Updates
You do not need to repeat the install block to get new improvements. Simply run:
```bash
sudo disk-health --update
```

### Display Help
```bash
disk-health --help
```

### Example Output

```text
Checking Disk Health...

------------------------------------
Disk: /dev/sda
Model: Samsung SSD 850 EVO 500GB
Serial Number: DUMMYSERIAL12345
Firmware: EMT02B6Q
Type: SATA SSD
Capacity: 500G
Status: PASSED
Health: 98%
Temperature: 33°C
Power On Time: 217 days 4 hours 0 minutes
Data Written: 8.20 TB
------------------------------------
Disk: /dev/nvme0n1
Model: Generic Ultra-Fast NVMe 1TB
Serial Number: DUMMYNVME12345
Firmware: 1024XB1
Type: NVMe SSD
Capacity: 1T
Status: PASSED
Health: 100%
Temperature: 48°C
Power On Time: 45 days 10 hours 0 minutes
Data Written: 4.10 TB
------------------------------------
```

## 📚 Documentation
For complete technical details, fallback logic explanations, and in-depth mechanic transparency, explore the full documentation using [our developer manual](docs/src/MANUAL.md).

## 📄 License

This project is licensed under the [Apache License](LICENSE). Feel free to contribute, modify, and distribute it!
