#!/bin/bash
# Easy installer for OSWriter
# This script downloads the latest version from GitHub and runs the installer

echo "=== OSWriter Easy Installer ==="
echo "Downloading the latest version from GitHub..."

# Create a temporary directory
TMP_DIR=$(mktemp -d)

# Download the ZIP archive from GitHub
curl -SL https://github.com/TheSoftwareWizard/oswriter/archive/refs/heads/master.zip -o "$TMP_DIR/oswriter.zip"

if [ $? -ne 0 ]; then
  echo "Failed to download the archive. Check your internet connection."
  exit 1
fi

echo "Extracting files..."
unzip -q "$TMP_DIR/oswriter.zip" -d "$TMP_DIR"

if [ $? -ne 0 ]; then
  echo "Failed to extract the archive."
  exit 1
fi

echo "Running installer..."
cd "$TMP_DIR/oswriter-master"
sudo bash install.sh

# Clean up
rm -rf "$TMP_DIR"

echo "Installation complete!"
