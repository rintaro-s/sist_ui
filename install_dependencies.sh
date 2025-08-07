#!/bin/bash

set -e

echo "Updating package lists..."
sudo apt update

echo "Installing build dependencies from debian/control..."
sudo apt install -y debhelper qt6-base-dev qt6-declarative-dev qt6-graphicaleffects-dev qt6-multimedia-dev

echo "Installing common Qt6 QML modules..."
sudo apt install -y qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-window qml6-module-qtgraphicaleffects qml6-module-qtmultimedia

echo "Installing recommended external applications (Chromium, Nautilus)..."
sudo apt install -y chromium-browser nautilus

echo "All specified dependencies and applications have been installed."
echo "Please ensure Flutter SDK is also installed and configured if you haven't already."
