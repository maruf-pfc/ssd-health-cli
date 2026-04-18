# Contributing to disk-health-cli

First off, thank you for considering contributing to `disk-health-cli`! It's people like you that make open-source software such a great community.

## 🛠️ How to Contribute

### 1. Reporting Bugs
This section guides you through submitting a bug report. Following these guidelines helps maintainers understand your report, reproduce the behavior, and find related reports.
- Use the provided **Bug Report** issue template.
- Explain the behavior you expected and the actual behavior.
- Include the exact output you received and mention your OS/Disk setup.

### 2. Suggesting Enhancements
This section guides you through submitting an enhancement suggestion, including completely new features and minor improvements to existing functionality.
- Use the provided **Feature Request** issue template.
- Explain why this enhancement would be useful to most users.

### 3. Pull Requests
The process described here has several goals:
- Maintain `disk-health-cli`'s quality.
- Fix problems that are important to users.
- Enable a sustainable system for `disk-health-cli`'s maintainers to review contributions.

Please follow these steps to have your contribution considered by the maintainers:
1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add notes on how you verified it.
3. Ensure the script linting passes (we recommend using `shellcheck disk-health.sh`).
4. Update the documentation in the `docs/` folder or `README.md` if you are changing functionality.
5. Create a Pull Request using the provided template.

## 👨‍💻 Local Development

1. Fork the repository.
2. Clone your fork locally.
3. You can execute the script locally without installing: `sudo ./disk-health.sh`

### Code Style
- Use standard bash formatting (`#!/usr/bin/env bash`).
- Ensure all S.M.A.R.T parsing has a fallback for traditional and NVMe setups.
- Favor `awk` and `grep` natively without heavily chaining unnecessary pipes if possible.
- Avoid introducing new heavy dependencies if a standard UNIX utility is capable.
