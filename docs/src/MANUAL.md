---
layout: default
title: Comprehensive Manual
description: Deep dive into disk-health-cli mechanics and usage.
---

<style>
/* Clean up the tables so they stretch beautifully */
table { width: 100%; display: table; }
th, td { padding: 12px; }
tr:nth-child(even) { background-color: rgba(0,0,0,0.05); }
.dark-mode tr:nth-child(even) { background-color: rgba(255,255,255,0.05); }
</style>

# disk-health-cli Manual

Welcome to the definitive source of truth for **disk-health-cli**. This tool is engineered to quickly and effectively read hardware sensors to determine the genuine SMART health data of all local drives.

---

## 🛠️ Installation & Updates

The simplest way to use `disk-health-cli` is through the global one-line installer. 

### Fresh Install
This curl string safely fetches exactly one shell script and creates a `/usr/local/bin` linkage so you can call `disk-health` anywhere inside your system organically.
```bash
curl -sSfL https://raw.githubusercontent.com/blackstart-labs/disk-health-cli/main/install.sh | sudo bash
```

### Self Updating
You do not need to repeat the install block above once deployed. Run the built-in update hook any time you want to fetch new features or logic improvements:
```bash
sudo disk-health --update
```

---

## 💡 Usage & Flags

Our goal isn't replacing `smartmontools` entirely but making the 99% usage—health verification—accessible at a glance.

```bash
# General Check
sudo disk-health

# Display Help
disk-health --help

# Ensure you are on the newest codebase
sudo disk-health --update
```

### Output Breakdown

When running `disk-health` you will receive a block per connected drive. Here is how we generate each field:

| Output Field | Context | Hardware Specifics |
| :--- | :--- | :--- |
| **Model** | Name of the hardware. | Parsed directly from SMART logic models. |
| **Status** | Overall generic `PASSED` / `FAILED` state. | Reads primary generic SMART assessment status. |
| **Health** | Expected percentage life remaining. | SATA uses `Available_Reservd_Space` or `Wear_Leveling_Count`. NVMe uses `percentage_used` inversion. HDDs fall back to reallocated sector tracking due to a lack of overall %. |
| **Temperature** | Operating heat in Celsius. | Fully supports raw Kelvin conversion from certain Debian `nvme-cli` builds to Celsius automatically. |
| **Data Written** | TBW (Terabytes Written). | Formatted nicely for NVMe and SSD drives by calculating Total LBAs written against 512 byte sectors. |

---

## ⚙️ Architecture & Mechanics

`disk-health-cli` heavily prioritizes clean dependency handling and accurate logic fallbacks.

1. **Dependency Auto-Resolution**: When the script boots it validates if `smartmontools`, `nvme-cli`, `gawk`, and `util-linux` exist. If they do not, it leverages `apt`, `dnf`, or `pacman` automatically behind a sudo gate to install exactly what it needs for you. No manual downloading.
2. **NVMe Fallback System**: We default to `nvme-cli` for modern M.2 drives because S.M.A.R.T. logic isn't natively standard for them. If it fails, our `awk` handlers map seamlessly backward to secondary `smartmontools` definitions.
3. **Regex Safe Patterning**: By utilizing strict anchored `awk` regexs, we eliminate greedy multi-line captures that cause traditional bash scrapers to fail on arrays passing multiple `temperature_sensor_#` keys.
