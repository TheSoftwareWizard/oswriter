# OSWriter

A command-line tool for creating bootable USB drives from various operating system images.

![OSWriter Version](https://img.shields.io/badge/version-0.4.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Automatic USB detection**: Detects and lists all connected USB drives
- **Multiple OS support**: Create bootable USB drives for:
  - Linux distributions (Ubuntu, Debian, etc.)
  - Windows
  - Custom images
- **Ventoy integration**: Option to install Ventoy for multi-boot USB creation
- **Safety measures**: Multiple safeguards to prevent formatting system disks by mistake
- **Interactive interface**: Clear menus and confirmation prompts
- **Auto-updates**: Check for and install updates easily
- **Path autocompletion**: Tab completion support when entering file paths
- **Wi-Fi management**: Built-in tools for managing network connections (Linux only)

## Requirements

- Linux operating system (tested on Fedora, Ubuntu, Debian, Raspberry Pi OS)
- Root privileges (sudo)
- Basic tools: `lsblk`, `dd`, `file`
- Optional tools depending on usage:
  - `woeusb` or `woeusb-ng` for Windows ISO support
  - `ventoy` for multi-boot support

## Installation

### Quick Installation (Recommended)

For local installation from a cloned repository:

```bash
cd oswriter
sudo ./install.sh
```

After installation, you can run OSWriter by typing:

```bash
sudo oswriter
```

or

```bash
sudo create_bootable_usb
```

### Uninstallation

To remove OSWriter from your system:

```bash
sudo oswriter uninstall
```

or

```bash
sudo ./install.sh uninstall
```

## Usage

When using the installed version:

```bash
sudo oswriter
```

Or if you manually downloaded the script:

```bash
sudo ./create_bootable_usb.sh
```

### Menu Options

1. **Create a bootable USB drive** - The main functionality
2. **Check for updates** - Update OSWriter to the latest version
0. **Exit** - Close the application

### OS Options

1. **Ubuntu/Debian/Other Linux distributions (ISO)** - For Linux-based distributions
2. **Windows (ISO)** - For Windows installation media (requires woeusb or woeusb-ng)
3. **Ventoy (for multiple operating systems)** - Install Ventoy to create multi-boot USB
4. **Custom image (using dd)** - For any other disk image

### Additional Features

- **Tab autocompletion**: Press Tab to autocomplete file paths when selecting an ISO
- **Wi-Fi management**: Tools for connecting to networks (on Linux systems)
- **Automatic updates**: OSWriter checks for updates and can update itself

## Safety Features

OSWriter includes multiple safety checks to protect your system:

- Prevents formatting of NVMe and other system disks
- Detects and warns about large drives
- Confirms removable media status
- Requires explicit confirmation before formatting
- Checks for mounted system partitions

## Warning

**ALL DATA ON THE SELECTED USB DRIVE WILL BE ERASED!**

Always double-check that you've selected the correct drive before confirming.

## Troubleshooting

### Common Issues

- **"Not enough free space"**: Ensure your USB drive has enough capacity for the ISO
- **WoeUSB errors**: For Windows ISOs, ensure you have woeusb or woeusb-ng installed
- **Permissions issues**: Make sure to run with sudo

### OS-Specific Notes

- **Fedora**: Install woeusb-ng via `sudo dnf install woeusb-ng`
- **Ubuntu/Debian**: Install woeusb-ng via `sudo apt install woeusb-ng`
- **Raspberry Pi**: For Wi-Fi management, ensure Network Manager is enabled in raspi-config

## License

MIT License

## Author

TheSoftwareWizard - [GitHub](https://github.com/TheSoftwareWizard)

## Version History

- **0.4.1** - Added version number and MIT license information
- **0.4.0** - Improved path handling and error detection
- **0.3.0** - Added auto-update capabilities
- **0.2.0** - Added tab autocompletion for file paths
- **0.1.0** - Initial release 