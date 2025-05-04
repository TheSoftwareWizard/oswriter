#!/bin/bash
#
# create_bootable_usb.sh - Script for creating bootable USB drives
# Author: TheSoftwareWizard
# Project: oswriter - https://github.com/TheSoftwareWizard/oswriter
# Version: 0.4.1
# License: MIT
#
# This script allows creating bootable USB drives for different operating systems
# from the terminal, automatically detecting connected USB drives and
# guiding the user through an interactive menu.

# Stop the script if any error occurs
set -e

# Colors for better presentation
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display formatted messages
show_message() {
    echo -e "${2}${1}${NC}" >&2
}

# Function to show script header with author and project info
show_header() {
    clear
    show_message "===== BOOTABLE USB CREATOR =====" "$BLUE"
    show_message "This script will help you create a bootable USB drive" "$BLUE"
    show_message "for different operating systems." "$BLUE"
    echo ""
    show_message "Author: TheSoftwareWizard" "$GREEN"
    show_message "Project: oswriter - https://github.com/TheSoftwareWizard/oswriter" "$GREEN"
    show_message "Version: 0.4.1" "$GREEN"
    show_message "License: MIT" "$GREEN"
    echo ""
}

# Function to check if the script is running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        show_message "This script needs superuser (root) privileges." "$RED"
        show_message "Please run it with sudo: sudo $0" "$YELLOW"
        exit 1
    fi
}

# Function to check dependencies
check_dependencies() {
    local required_deps=("lsblk" "dd" "file")
    local optional_deps=("ventoy" "woeusb" "woeusb-ng")
    local missing_required=()
    local missing_optional=()

    # Check required dependencies
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_required+=("$dep")
        fi
    done

    # Exit if any required dependency is missing
    if [ ${#missing_required[@]} -gt 0 ]; then
        show_message "ERROR: Missing required dependencies:" "$RED"
        for dep in "${missing_required[@]}"; do
            show_message "- $dep" "$RED"
        done
        show_message "Please install them before continuing." "$YELLOW"
        exit 1
    fi

    # Check optional tools
    for dep in "${optional_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_optional+=("$dep")
        fi
    done

    # Warn about missing optional dependencies
    if [[ " ${missing_optional[*]} " =~ " ventoy " ]]; then
        show_message "Ventoy is not installed. Will use dd as an alternative for Linux." "$YELLOW"
    fi
    
    if [[ " ${missing_optional[*]} " =~ " woeusb " ]] && [[ " ${missing_optional[*]} " =~ " woeusb-ng " ]]; then
        show_message "WoeUSB is not installed. It may be needed to create Windows bootable USBs." "$YELLOW"
    fi
}

# Function to detect USB drives
detect_usb_drives() {
    show_message "Detecting connected USB drives..." "$BLUE"
    
    # Show devices found - specifically filter by USB transport type
    echo "Devices found:"
    lsblk -d -o NAME,SIZE,MODEL,VENDOR,TRAN,HOTPLUG,TYPE,MOUNTPOINT | grep -i "usb" | sort
}

# Function to select a USB drive
select_usb_drive() {
    # Get only removable devices connected via USB
    # Filter explicitly by TRAN=usb
    local drives=($(lsblk -d -n -o NAME,TRAN | grep -i "usb" | awk '{print $1}'))
    local removable_drives=()
    
    # Display a clear warning about system disks
    show_message "IMPORTANT: This script will only show USB devices for safety." "$RED"
    echo "" >&2
    
    # Filter to remove any system disk from the list
    for drive in "${drives[@]}"; do
        # Explicitly skip any NVMe devices
        if [[ $drive == nvme* ]]; then
            continue
        fi
        
        # Explicitly check /sys for removable attribute
        removable=$(cat /sys/block/$drive/removable 2>/dev/null || echo "0")
        if [ "$removable" != "1" ]; then
            continue
        fi
        
        # Check for mounted system partitions
        mount_points=$(lsblk -n -o MOUNTPOINT /dev/$drive | grep -E "^/$|^/boot|^/home|^/usr")
        if [ ! -z "$mount_points" ]; then
            continue
        fi
        
        # Add to the list if it passed all checks
        removable_drives+=("$drive")
    done
    
    drives=("${removable_drives[@]}")
    
    if [ ${#drives[@]} -eq 0 ]; then
        show_message "No safe removable USB drives found." "$RED"
        exit 1
    elif [ ${#drives[@]} -eq 1 ]; then
        show_message "USB drive detected: /dev/${drives[0]}" "$GREEN"
        
        # Show drive details
        local size=$(lsblk -d -n -o SIZE /dev/${drives[0]})
        local model=$(lsblk -d -n -o MODEL /dev/${drives[0]} | tr -d ' ')
        
        show_message "Drive details:" "$YELLOW"
        show_message "- Device: /dev/${drives[0]}" "$YELLOW"
        show_message "- Size: $size" "$YELLOW"
        show_message "- Model: $model" "$YELLOW"
        
        # Add confirmation to use this drive
        echo -n "Do you want to use this drive? (y/n): " >&2
        read confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            # Fix: Debug the value being returned
            show_message "Selected drive: /dev/${drives[0]}" "$GREEN"
            # Fix: Ensure we properly return the device path
            echo "/dev/${drives[0]}"
            return 0
        else
            show_message "Operation canceled by the user." "$YELLOW"
            exit 0
        fi
    else
        show_message "Multiple USB drives detected. Please select one:" "$BLUE"
        for i in "${!drives[@]}"; do
            echo "[$i] /dev/${drives[$i]} ($(lsblk -d -n -o SIZE,MODEL /dev/${drives[$i]} | tr -s ' '))" >&2
        done
        
        while true; do
            echo -n "Enter the number of the USB drive you want to use: " >&2
            read selection
            if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -lt "${#drives[@]}" ]; then
                show_message "You selected: /dev/${drives[$selection]}" "$GREEN"
                
                # Additional information and safety confirmation
                local size=$(lsblk -d -n -o SIZE /dev/${drives[$selection]})
                local model=$(lsblk -d -n -o MODEL /dev/${drives[$selection]} | tr -d ' ')
                
                show_message "ATTENTION: All data on this drive will be erased." "$RED"
                show_message "Drive details:" "$YELLOW"
                show_message "- Device: /dev/${drives[$selection]}" "$YELLOW"
                show_message "- Size: $size" "$YELLOW"
                show_message "- Model: $model" "$YELLOW"
                
                echo -n "Are you SURE you want to continue? (type 'CONFIRM' to proceed): " >&2
                read final_confirm
                if [ "$final_confirm" = "CONFIRM" ]; then
                    # Return the selected drive explicitly
                    echo "/dev/${drives[$selection]}"
                    return 0
                else
                    show_message "Operation canceled by the user." "$YELLOW"
                    exit 0
                fi
            else
                show_message "Invalid selection. Please try again." "$RED"
            fi
        done
    fi
}

# Function to display the operating system menu
show_os_menu() {
    show_message "Select the operating system you want to install:" "$BLUE"
    
    # Print menu options directly to stderr to avoid capturing in function output
    cat << EOF >&2
1) Ubuntu/Debian/Other Linux distributions (ISO)
2) Windows (ISO)
3) Ventoy (for multiple operating systems)
4) Custom image (using dd)
0) Exit
EOF
    
    # Get user choice - store in separate variable to avoid capturing menu text
    local choice=""
    while true; do
        read -p "Enter your choice (0-4): " choice >&2
        case "$choice" in
            [0-4]) 
                # Only return the number, nothing else
                echo "$choice"
                return 
                ;;
            *) 
                show_message "Invalid option. Please try again." "$RED" 
                ;;
        esac
    done
}

# Function to verify an ISO image
verify_iso() {
    local iso_path="$1"
    
    # Check that the file exists
    if [ ! -f "$iso_path" ]; then
        show_message "Error: The file '$iso_path' does not exist." "$RED"
        return 1
    fi
    
    # Check that it's a regular file
    if [ ! -r "$iso_path" ]; then
        show_message "Error: Cannot read the file '$iso_path'." "$RED"
        return 1
    fi
    
    # Check that it's an ISO image (basic file type verification)
    file_type=$(file -b "$iso_path" | grep -i "ISO 9660")
    if [[ -z "$file_type" && "$os_choice" != "4" ]]; then
        show_message "Warning: The file does not appear to be a valid ISO image." "$YELLOW"
        show_message "File type: $(file -b "$iso_path")" "$YELLOW"
        read -p "Do you want to continue anyway? (y/n): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Show image information
    local iso_size=$(du -h "$iso_path" | cut -f1)
    show_message "Image verification completed:" "$GREEN"
    show_message "- Path: $iso_path" "$GREEN"
    show_message "- Size: $iso_size" "$GREEN"
    
    return 0
}

# Function to create Linux bootable USB with dd
create_linux_usb() {
    local usb_drive="$1"
    local iso_path="$2"
    
    show_message "Creating bootable USB for Linux..." "$BLUE"
    show_message "WARNING: This process will FORMAT and erase ALL data on $usb_drive" "$RED"
    read -p "Are you sure you want to continue? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        show_message "Operation canceled by the user." "$YELLOW"
        return 1
    fi
    
    show_message "Formatting and preparing drive..." "$YELLOW"
    show_message "Copying the ISO image to the USB drive. Please wait..." "$BLUE"
    
    # Use dd to copy the image
    dd if="$iso_path" of="$usb_drive" bs=4M status=progress conv=fsync
    
    if [ $? -eq 0 ]; then
        sync
        show_message "Linux bootable USB created successfully!" "$GREEN"
        return 0
    else
        show_message "Error creating the bootable USB." "$RED"
        return 1
    fi
}

# Function to create Windows bootable USB with WoeUSB
create_windows_usb() {
    local usb_drive="$1"
    local iso_path="$2"
    
    # Check that WoeUSB is installed
    if command -v woeusb &> /dev/null; then
        woeusb_cmd="woeusb"
    elif command -v woeusb-ng &> /dev/null; then
        woeusb_cmd="woeusb-ng"
    else
        show_message "Error: WoeUSB is not installed." "$RED"
        show_message "Install WoeUSB to create Windows bootable USBs:" "$YELLOW"
        show_message "For Ubuntu/Debian: sudo apt install woeusb or woeusb-ng" "$YELLOW"
        return 1
    fi
    
    # Check if ISO is larger than drive
    local iso_size=$(du -b "$iso_path" | cut -f1)
    local drive_size=$(lsblk -b -d -n -o SIZE "$usb_drive")
    
    if [ "$iso_size" -gt "$drive_size" ]; then
        show_message "Error: The ISO image ($(du -h "$iso_path" | cut -f1)) is larger than your USB drive ($(lsblk -d -n -o SIZE "$usb_drive"))." "$RED"
        show_message "Please use a larger USB drive or a smaller ISO image." "$YELLOW"
        return 1
    fi
    
    show_message "Creating bootable USB for Windows..." "$BLUE"
    show_message "WARNING: This process will FORMAT and erase ALL data on $usb_drive" "$RED"
    read -p "Are you sure you want to continue? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        show_message "Operation canceled by the user." "$YELLOW"
        return 1
    fi
    
    show_message "Formatting and preparing drive..." "$YELLOW"
    show_message "Copying the ISO image to the USB drive. This process may take a long time..." "$BLUE"
    
    # Create a temporary file for the WoeUSB output
    local temp_output_file=$(mktemp)
    
    # Use WoeUSB to create the Windows bootable USB and save output
    if [ "$woeusb_cmd" = "woeusb" ]; then
        "$woeusb_cmd" --target-filesystem NTFS --device "$iso_path" "$usb_drive" 2>&1 | tee "$temp_output_file"
    else
        "$woeusb_cmd" --target "$usb_drive" --source "$iso_path" --target-filesystem ntfs 2>&1 | tee "$temp_output_file"
    fi
    
    # Capture the exit code
    local woeusb_result=${PIPESTATUS[0]}
    
    # Also check for specific error strings in the output
    grep -q "Error:" "$temp_output_file"
    local error_found=$?
    
    # Remove the temporary file
    rm "$temp_output_file"
    
    # Sync to ensure all writes are complete
    sync
    
    if [ $woeusb_result -eq 0 ] && [ $error_found -ne 0 ]; then
        show_message "Windows bootable USB created successfully!" "$GREEN"
        return 0
    else
        show_message "Error: Failed to create Windows bootable USB." "$RED"
        
        if [ "$iso_size" -gt "$((drive_size * 9 / 10))" ]; then
            show_message "The ISO may be too large for this USB drive." "$YELLOW"
            show_message "ISO size: $(du -h "$iso_path" | cut -f1)" "$YELLOW"
            show_message "USB drive size: $(lsblk -d -n -o SIZE "$usb_drive")" "$YELLOW"
        fi
        
        return 1
    fi
}

# Function to install Ventoy on a USB drive
install_ventoy() {
    local usb_drive="$1"
    
    # Check that Ventoy is installed
    if ! command -v ventoy &> /dev/null; then
        show_message "Error: Ventoy is not installed." "$RED"
        show_message "You can install Ventoy from https://www.ventoy.net/en/download.html" "$YELLOW"
        return 1
    fi
    
    show_message "Installing Ventoy on the USB drive..." "$BLUE"
    show_message "WARNING: This process will FORMAT and erase ALL data on $usb_drive" "$RED"
    read -p "Are you sure you want to continue? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        show_message "Operation canceled by the user." "$YELLOW"
        return 1
    fi
    
    # Install Ventoy
    ventoy -i "$usb_drive"
    
    # Capture return code explicitly
    local ventoy_result=$?
    
    if [ $ventoy_result -eq 0 ]; then
        show_message "Ventoy successfully installed on $usb_drive!" "$GREEN"
        show_message "You can now copy ISO images directly to the Ventoy partition." "$GREEN"
        return 0
    else
        show_message "Error installing Ventoy." "$RED"
        return 1
    fi
}

# Function to create bootable USB with custom image
create_custom_usb() {
    local usb_drive="$1"
    local img_path="$2"
    
    show_message "Creating bootable USB with custom image..." "$BLUE"
    show_message "WARNING: This process will FORMAT and erase ALL data on $usb_drive" "$RED"
    read -p "Are you sure you want to continue? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        show_message "Operation canceled by the user." "$YELLOW"
        return 1
    fi
    
    show_message "Formatting and preparing drive..." "$YELLOW"
    show_message "Copying the image to the USB drive. Please wait..." "$BLUE"
    
    # Use dd to copy the image
    dd if="$img_path" of="$usb_drive" bs=4M status=progress conv=fsync
    
    if [ $? -eq 0 ]; then
        sync
        show_message "Bootable USB with custom image created successfully!" "$GREEN"
        return 0
    else
        show_message "Error creating the bootable USB." "$RED"
        return 1
    fi
}

# Function to check for updates
check_for_updates() {
    show_message "Checking for updates..." "$BLUE"
    
    # Get the current script path
    local current_script="$0"
    
    # Check if we're running the installed version
    if [[ "$current_script" == "/usr/local/bin/oswriter" || "$current_script" == "/usr/local/bin/create_bootable_usb" ]]; then
        # We're running the installed version, we can update
        show_message "Downloading the latest version..." "$YELLOW"
        
        # Create temporary directory
        local temp_dir=$(mktemp -d)
        
        # Download directly with curl - NO GIT
        curl -s -f -o "$temp_dir/create_bootable_usb.sh" https://raw.githubusercontent.com/TheSoftwareWizard/oswriter/master/create_bootable_usb.sh
        
        if [ $? -eq 0 ] && [ -s "$temp_dir/create_bootable_usb.sh" ]; then
            # Check if it's a valid shell script
            if head -n1 "$temp_dir/create_bootable_usb.sh" | grep -q "#!/bin/bash"; then
                # Check if the version is different
                if ! diff -q "$current_script" "$temp_dir/create_bootable_usb.sh" >/dev/null; then
                    # Copy the new version
                    show_message "Installing the new version..." "$YELLOW"
                    cp "$temp_dir/create_bootable_usb.sh" "$current_script"
                    chmod +x "$current_script"
                    show_message "Update completed successfully!" "$GREEN"
                    show_message "Please restart the script to use the new version." "$GREEN"
                    rm -rf "$temp_dir"
                    exit 0
                else
                    show_message "You already have the latest version." "$GREEN"
                fi
            else
                show_message "Update check failed: Downloaded file is not a valid script." "$RED"
            fi
        else
            show_message "Failed to download the update." "$RED"
            show_message "Please check your internet connection and try again." "$YELLOW"
        fi
        
        # Clean up
        rm -rf "$temp_dir"
        return 0
    else
        # We're running from a custom location
        show_message "You are not running the installed version." "$YELLOW"
        show_message "Updates are only available for the installed version." "$YELLOW"
        show_message "Run 'sudo oswriter' or 'sudo create_bootable_usb' to use the installed version." "$YELLOW"
        return 1
    fi
}

# Function to uninstall OSWriter
uninstall_oswriter() {
    show_message "===== OSWRITER UNINSTALLER =====" "$BLUE"
    show_message "This will remove OSWriter from your system." "$BLUE"
    echo ""
    
    # Remove installed files
    if [ -f "/usr/local/bin/oswriter" ]; then
        rm -f "/usr/local/bin/oswriter"
        show_message "Removed /usr/local/bin/oswriter" "$GREEN"
    fi
    
    if [ -L "/usr/local/bin/create_bootable_usb" ]; then
        rm -f "/usr/local/bin/create_bootable_usb"
        show_message "Removed /usr/local/bin/create_bootable_usb" "$GREEN"
    fi
    
    if [ -d "/etc/oswriter" ]; then
        rm -rf "/etc/oswriter"
        show_message "Removed /etc/oswriter directory" "$GREEN"
    fi
    
    show_message "OSWriter has been successfully uninstalled!" "$GREEN"
    exit 0
}

# Show the main menu and get user's choice
show_main_menu() {
    show_message "What would you like to do?" "$BLUE"
    
    cat << EOF >&2
1) Create a bootable USB drive
2) Check for updates
0) Exit
EOF
    
    # Get user choice
    local choice=""
    while true; do
        read -p "Enter your choice (0-2): " choice >&2
        case "$choice" in
            [0-2]) 
                echo "$choice"
                return 
                ;;
            *) 
                show_message "Invalid option. Please try again." "$RED" 
                ;;
        esac
    done
}

# Main function
main() {
    # Process arguments first
    if [ "$1" = "uninstall" ]; then
        # Check root privileges for uninstall
        check_root
        uninstall_oswriter
        exit 0
    fi
    
    # Show header with author/project info
    show_header
    
    # Check root privileges
    check_root
    
    # Check dependencies
    check_dependencies
    
    # Check for auto-updates if installed version and AUTO_UPDATE is enabled
    if [[ "$0" == "/usr/local/bin/oswriter" || "$0" == "/usr/local/bin/create_bootable_usb" ]]; then
        # Only check once a day to avoid slowing down the script
        last_update_check="/tmp/oswriter_update_check"
        current_date=$(date +%Y%m%d)
        
        # Check if we should verify updates today
        if [ ! -f "$last_update_check" ] || [ "$(cat "$last_update_check")" != "$current_date" ]; then
            show_message "Checking for updates..." "$BLUE"
            
            # Create temporary directory
            temp_update_dir=$(mktemp -d)
            update_found=false
            
            # Try to download the latest version
            curl -f -s -o "$temp_update_dir/create_bootable_usb.sh" https://raw.githubusercontent.com/TheSoftwareWizard/oswriter/master/create_bootable_usb.sh
            
            # Check if download was successful (-f makes curl return non-zero on server errors)
            if [ $? -eq 0 ] && [ -s "$temp_update_dir/create_bootable_usb.sh" ]; then
                # Check if it's a valid shell script
                if head -n1 "$temp_update_dir/create_bootable_usb.sh" | grep -q "#!/bin/bash"; then
                    # Check if the version is different
                    if ! diff -q "$0" "$temp_update_dir/create_bootable_usb.sh" >/dev/null; then
                        show_message "A new version is available. Updating..." "$YELLOW"
                        cp "$temp_update_dir/create_bootable_usb.sh" "$0"
                        chmod +x "$0"
                        show_message "Update completed successfully! Restarting..." "$GREEN"
                        rm -rf "$temp_update_dir"
                        echo "$current_date" > "$last_update_check"
                        exec "$0" "$@"
                        exit 0
                    else
                        show_message "You have the latest version." "$GREEN"
                    fi
                else
                    show_message "Update check failed: Downloaded file is not a valid script." "$RED"
                fi
            else
                show_message "Update check failed: Unable to download latest version." "$RED"
            fi
            
            # Clean up
            rm -rf "$temp_update_dir"
            echo "$current_date" > "$last_update_check"
        fi
    fi
    
    # Show main menu first
    local main_choice=$(show_main_menu)
    
    case "$main_choice" in
        "0")
            show_message "Exiting the script. Goodbye!" "$GREEN"
            exit 0
            ;;
        "1")
            # Create bootable USB - Continue with existing code
            ;;
        "2")
            # Check for updates
            check_for_updates
            exit 0
            ;;
        *)
            show_message "Invalid option. Exiting." "$RED"
            exit 1
            ;;
    esac
    
    # Detect USB drives
    detect_usb_drives
    
    # Select USB drive - IMPORTANT: Capture only the last line output by the function
    usb_drive=$(select_usb_drive)
    
    # Additional check to ensure usb_drive has a valid value
    if [ -z "$usb_drive" ] || [[ ! "$usb_drive" == /dev/* ]]; then
        show_message "Error: No valid USB drive selected (got: $usb_drive)." "$RED"
        exit 1
    fi
    
    # Show that we're using the selected drive
    show_message "Using drive: $usb_drive" "$GREEN"
    
    # Show operating system menu - STORE ONLY THE NUMBER
    os_choice=$(show_os_menu)
    
    # Variable to store the ISO image path
    iso_path=""
    
    # Process according to user's choice
    case "$os_choice" in
        "0")
            show_message "Exiting the script. Goodbye!" "$GREEN"
            exit 0
            ;;
        "1"|"2"|"4")
            # Linux, Windows, or custom image - MAKE SURE THIS PROMPT IS DISPLAYED
            echo -e "\nYou'll need to provide an ISO file for the installation."
            
            # Use a named temporary file that's easy to clean up
            TMP_SCRIPT="/tmp/oswriter_input_$$"
            cat > "$TMP_SCRIPT" << 'EOF'
#!/bin/bash

# Enable tab completion in a more compatible way
if [[ $- == *i* ]]; then
    # Only execute these in an interactive shell
    bind "set completion-ignore-case on" 2>/dev/null
    bind "set completion-map-case on" 2>/dev/null
    bind "set show-all-if-ambiguous on" 2>/dev/null
    bind "set menu-complete-display-prefix on" 2>/dev/null
fi

# Force bash to use readline
INPUTRC_TMP=$(mktemp)
cat > "$INPUTRC_TMP" << 'INNEREOF'
set completion-ignore-case on
set completion-map-case on
set show-all-if-ambiguous on
set menu-complete-display-prefix on
INNEREOF

export INPUTRC="$INPUTRC_TMP"
read -e -p "Enter the full path to the ISO image: " iso_path
rm -f "$INPUTRC_TMP"
echo "$iso_path"
EOF
            chmod +x "$TMP_SCRIPT"
            
            while true; do
                # Run the input script as the original user for proper autocompletion
                if [ -n "$SUDO_USER" ]; then
                    iso_path=$(sudo -u "$SUDO_USER" bash -c "$TMP_SCRIPT")
                else
                    iso_path=$("$TMP_SCRIPT")
                fi
                
                # Better path handling - handle relative paths and tilde expansion
                if [[ "$iso_path" == ~* ]]; then
                    # Handle paths with tilde
                    if [ -n "$SUDO_USER" ]; then
                        USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
                        iso_path="${iso_path/#\~/$USER_HOME}"
                    else
                        iso_path="${iso_path/#\~/$HOME}"
                    fi
                elif [[ "$iso_path" != /* ]]; then
                    # Handle relative paths when running as root
                    if [ -n "$SUDO_USER" ]; then
                        USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
                        iso_path="$USER_HOME/$iso_path"
                    else
                        iso_path="$HOME/$iso_path"
                    fi
                fi
                
                # Show the expanded path for debugging
                show_message "Looking for ISO at: $iso_path" "$BLUE"
                
                if verify_iso "$iso_path"; then
                    # Clean up the temp script on success
                    rm -f "$TMP_SCRIPT"
                    break
                else
                    show_message "Please provide a valid path." "$RED"
                fi
            done
            
            # Variable to store operation result
            operation_success=false
            
            case "$os_choice" in
                "1") 
                    if create_linux_usb "$usb_drive" "$iso_path"; then
                        operation_success=true
                    fi
                    ;;
                "2") 
                    if create_windows_usb "$usb_drive" "$iso_path"; then
                        operation_success=true
                    fi
                    ;;
                "4") 
                    if create_custom_usb "$usb_drive" "$iso_path"; then
                        operation_success=true
                    fi
                    ;;
            esac
            ;;
        "3")
            # Install Ventoy
            if install_ventoy "$usb_drive"; then
                operation_success=true
            else
                operation_success=false
            fi
            ;;
        *)
            show_message "Invalid option: $os_choice" "$RED"
            exit 1
            ;;
    esac
    
    if [ "$operation_success" = "true" ]; then
        show_message "===== SUMMARY =====" "$GREEN"
        show_message "Operation completed on drive: $usb_drive" "$GREEN"
        
        case "$os_choice" in
            "1") 
                show_message "Operating system: Linux" "$GREEN"
                show_message "Image used: $iso_path" "$GREEN"
                if [ -f "$iso_path" ]; then
                    show_message "Image size: $(du -h "$iso_path" | cut -f1)" "$GREEN"
                fi
                ;;
            "2") 
                show_message "Operating system: Windows" "$GREEN"
                show_message "Image used: $iso_path" "$GREEN"
                if [ -f "$iso_path" ]; then
                    show_message "Image size: $(du -h "$iso_path" | cut -f1)" "$GREEN"
                fi
                ;;
            "3") 
                show_message "Ventoy installation completed" "$GREEN"
                show_message "You can copy multiple ISOs to the Ventoy partition" "$GREEN"
                ;;
            "4") 
                show_message "Custom image" "$GREEN"
                show_message "Image used: $iso_path" "$GREEN"
                if [ -f "$iso_path" ]; then
                    show_message "Image size: $(du -h "$iso_path" | cut -f1)" "$GREEN"
                fi
                ;;
        esac
        
        echo ""
        show_message "Process completed! The USB drive is ready to use." "$GREEN"
    else
        show_message "===== SUMMARY =====" "$RED"
        show_message "Operation FAILED on drive: $usb_drive" "$RED"
        
        case "$os_choice" in
            "1") 
                show_message "Failed to create Linux bootable USB" "$RED"
                ;;
            "2") 
                show_message "Failed to create Windows bootable USB" "$RED"
                ;;
            "3") 
                show_message "Failed to install Ventoy" "$RED"
                ;;
            "4") 
                show_message "Failed to create bootable USB with custom image" "$RED"
                ;;
        esac
        
        echo ""
        show_message "Process failed! Please check the error messages above." "$RED"
        exit 1
    fi
}

# Execute the main function
main "$@" 