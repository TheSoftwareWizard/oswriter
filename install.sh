#!/bin/bash
#
# OSWriter Installation Script
# Author: TheSoftwareWizard
# Project: oswriter - https://github.com/TheSoftwareWizard/oswriter
#
# This script installs the OSWriter tool for creating bootable USB drives

# Colors for better presentation
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display formatted messages
show_message() {
    echo -e "${2}${1}${NC}"
}

# Function to check if script is running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        show_message "This installation script needs superuser (root) privileges." "$RED"
        show_message "Please run it with sudo: sudo bash install.sh" "$YELLOW"
        exit 1
    fi
}

# Main installation function
install_oswriter() {
    show_message "===== OSWRITER INSTALLER =====" "$BLUE"
    show_message "This script will install OSWriter on your system." "$BLUE"
    echo ""
    
    # Check root privileges
    check_root
    
    # Create installation directory
    install_dir="/usr/local/bin"
    config_dir="/etc/oswriter"
    
    show_message "Creating directories..." "$YELLOW"
    mkdir -p "$install_dir"
    mkdir -p "$config_dir"
    
    # Download the latest version of the script
    show_message "Installing OSWriter..." "$YELLOW"

    # Check if we're running from the repository
    if [ -f "./create_bootable_usb.sh" ]; then
        show_message "Found local script file, installing from local copy..." "$GREEN"
        cp "./create_bootable_usb.sh" "$install_dir/oswriter"
    else
        # Try to download from GitHub if not running from repo
        show_message "Downloading latest version of OSWriter..." "$YELLOW"
        curl -s https://raw.githubusercontent.com/TheSoftwareWizard/oswriter/master/create_bootable_usb.sh -o "$install_dir/oswriter"
        
        if [ $? -ne 0 ]; then
            show_message "Error: Failed to download OSWriter script." "$RED"
            show_message "Please check your internet connection and try again." "$YELLOW"
            exit 1
        fi
    fi
    
    # Make the script executable
    chmod +x "$install_dir/oswriter"
    
    # Create a symbolic link to make it available system-wide
    ln -sf "$install_dir/oswriter" "$install_dir/create_bootable_usb"
    
    # Check dependencies and suggest installation
    show_message "Checking dependencies..." "$YELLOW"
    dependencies=("lsblk" "dd" "file")
    missing_deps=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        show_message "Missing required dependencies: ${missing_deps[*]}" "$RED"
        show_message "Please install them using your package manager." "$YELLOW"
        show_message "For example: sudo apt install ${missing_deps[*]}" "$YELLOW"
    fi
    
    # Optional dependencies
    optional_deps=""
    
    # Check for Ventoy
    if ! command -v ventoy &> /dev/null; then
        optional_deps="${optional_deps} ventoy"
    fi
    
    # Check for WoeUSB
    if ! command -v woeusb &> /dev/null && ! command -v woeusb-ng &> /dev/null; then
        optional_deps="${optional_deps} woeusb-ng"
    fi
    
    if [ ! -z "$optional_deps" ]; then
        show_message "For full functionality, consider installing these optional dependencies:" "$YELLOW"
        show_message "${optional_deps}" "$YELLOW"
    fi
    
    # Installation complete
    show_message "OSWriter has been successfully installed!" "$GREEN"
    show_message "You can now run it by typing 'oswriter' or 'create_bootable_usb' in your terminal." "$GREEN"
    show_message "Remember to run it with sudo: sudo oswriter" "$GREEN"
    echo ""
    show_message "Thank you for installing OSWriter!" "$BLUE"
}

# Run the installation
install_oswriter 