# OSWriter

A command-line tool for creating bootable USB drives from various operating system images.

## Features

- **Automatic USB detection**: Detects and lists all connected USB drives
- **Multiple OS support**: Create bootable USB drives for:
  - Linux distributions (Ubuntu, Debian, etc.)
  - Windows
  - Custom images
- **Ventoy integration**: Option to install Ventoy for multi-boot USB creation
- **Safety measures**: Multiple safeguards to prevent formatting system disks by mistake
- **Interactive interface**: Clear menus and confirmation prompts

## Requirements

- Linux operating system
- Root privileges (sudo)
- Basic tools: `lsblk`, `dd`
- Optional tools depending on usage:
  - `woeusb` or `woeusb-ng` for Windows ISO support
  - `ventoy` for multi-boot support

## Installation

### Quick Installation (Recommended)

Install OSWriter directly from GitHub with a single command:

```bash
curl -sL https://raw.githubusercontent.com/TheSoftwareWizard/oswriter/master/install.sh | sudo bash
```

After installation, you can run OSWriter by typing:

```bash
sudo oswriter
```

### Manual Installation

If you prefer to manually install:

```bash
# Clone the repository
git clone https://github.com/TheSoftwareWizard/oswriter.git

# Change to the project directory
cd oswriter

# Make the script executable
chmod +x create_bootable_usb.sh

# Run the script
sudo ./create_bootable_usb.sh
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

Follow the interactive prompts to:
1. Select a USB drive
2. Choose the operating system type
3. Provide the path to the ISO image
4. Confirm the operation

## Safety Features

OSWriter includes multiple safety checks to protect your system:

- Prevents formatting of NVMe and other system disks
- Detects and warns about large drives (over 128GB)
- Confirms removable media status
- Requires explicit confirmation before formatting
- Checks for mounted system partitions

## Warning

**ALL DATA ON THE SELECTED USB DRIVE WILL BE ERASED!**

Always double-check that you've selected the correct drive before confirming.

## License

MIT License

## Author

TheSoftwareWizard - [GitHub](https://github.com/TheSoftwareWizard) 