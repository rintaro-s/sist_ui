#!/bin/bash

# --- Sist OS Robust Deployment Script ---
# This script automates the build and deployment process for the Sist OS shell.
# It includes checks for dependencies and required files, and backs up existing configurations.

# Immediately exit if any command fails
set -e

# --- Configuration ---
SRC_RC_XML="rc.xml"
SRC_AUTOSTART="autostart"
SRC_SIST_SESSION="sist-session"

DEST_APP_DIR="/opt/sist_ui"
DEST_OPENBOX_CONFIG_DIR="$HOME/.config/openbox"
DEST_SESSION_DIR="/usr/local/bin"

# --- Helper Functions ---
print_header() {
    echo ""
    echo "===================================================="
    echo " $1"
    echo "===================================================="
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ Error: Required command '$1' not found. Please install it and try again."
        exit 1
    fi
}

# --- Main Script ---

print_header "Starting Sist OS Deployment"

# 1. Prerequisite Checks
print_header "Step 1: Checking prerequisites"
check_command "flutter"
check_command "sudo"

for file in "$SRC_RC_XML" "$SRC_AUTOSTART" "$SRC_SIST_SESSION"; do
    if [ ! -f "$file" ]; then
        echo "❌ Error: Required source file '$file' not found in the current directory."
        exit 1
    fi
done
echo "✅ All prerequisites are met."

# 2. Flutter Build
print_header "Step 2: Building Flutter application"
echo "📦 Fetching packages..."
flutter pub get

echo "🛠️ Building application..."
flutter build linux
if [ $? -ne 0 ]; then
    echo "❌ Build failed. Aborting deployment."
    exit 1
fi
echo "✅ Build succeeded!"

# 3. Deploy Application
print_header "Step 3: Deploying application to $DEST_APP_DIR"
if [ -d "$DEST_APP_DIR" ]; then
    echo "   -> Found existing application. Removing it first."
    sudo rm -rf "$DEST_APP_DIR"
fi
sudo cp -r build/linux/x64/release/bundle "$DEST_APP_DIR"
echo "✅ Application deployed successfully."

# 4. Deploy Openbox Configuration
print_header "Step 4: Deploying Openbox configuration"
mkdir -p "$DEST_OPENBOX_CONFIG_DIR"

for file in "$SRC_RC_XML" "$SRC_AUTOSTART"; do
    dest_file="$DEST_OPENBOX_CONFIG_DIR/$(basename "$file")"
    if [ -f "$dest_file" ]; then
        echo "   -> Backing up existing '$dest_file' to '$dest_file.bak'"
        cp "$dest_file" "$dest_file.bak"
    fi
    echo "   -> Copying '$file' to '$dest_file'"
    cp "$file" "$dest_file"
done

echo "   -> Setting execute permission for autostart script."
chmod +x "$DEST_OPENBOX_CONFIG_DIR/autostart"
echo "✅ Openbox configuration deployed."

# 5. Fix ownership of config directory
print_header "Step 5: Fixing ownership of config directory"
echo "   -> Ensuring $USER owns all files in $HOME/.config"
sudo chown -R "$USER":"$USER" "$HOME/.config"
echo "✅ Ownership fixed."

# 6. Deploy Login Session Script
print_header "Step 6: Deploying login session script"
dest_file="$DEST_SESSION_DIR/sist-session"
echo "   -> Copying '$SRC_SIST_SESSION' to '$dest_file'"
sudo cp "$SRC_SIST_SESSION" "$dest_file"
echo "   -> Setting execute permission for session script."
sudo chmod +x "$dest_file"
echo "✅ Login session script deployed."

print_header "Deployment Complete!"
echo "🎉 All processes completed successfully!"
echo "   Please reboot your system to apply changes: sudo reboot"