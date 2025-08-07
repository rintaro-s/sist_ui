#!/bin/bash

# Exit on error
set -e

# --- Dependency Installation ---

echo "Updating package lists..."
sudo apt-get update

echo "Installing build tools, Qt6, and GTK..."
sudo apt-get install -y build-essential qt6-base-dev qt6-declarative-dev qt6-x11-extras-dev qml6-module-qtquick-controls2 libgtk-3-dev

echo "Installing Flutter dependencies..."
sudo apt-get install -y clang cmake ninja-build pkg-config

# --- Flutter SDK Installation ---

if ! command -v flutter &> /dev/null
then
    echo "Flutter SDK not found, installing..."
    # Use a writable directory for the SDK
    sudo mkdir -p /opt/flutter && sudo chown $USER /opt/flutter
    git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
    export PATH="$PATH:/opt/flutter/bin"
    flutter precache
    flutter doctor
else
    echo "Flutter SDK already installed."
fi

# --- Build ---

echo "Cleaning previous builds..."
rm -rf shell/build
rm -rf flutter_app/build

echo "Building the Flutter application first..."
cd flutter_app
flutter build linux --release
cd ..

echo "Building the Qt/QML shell..."
cd shell
mkdir -p build
cd build
qmake ..
make -j$(nproc)
cd ../../

# --- Run ---

echo "Starting the SIST UI desktop environment..."
./shell/build/shell
