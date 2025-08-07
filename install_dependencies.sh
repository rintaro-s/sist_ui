#!/bin/bash

set -e

echo "Updating package lists..."
sudo apt update

echo "Installing build dependencies from debian/control..."
sudo apt install -y debhelper qt6-base-dev qt6-declarative-dev qt6-5compat-dev qt6-multimedia-dev

echo "Installing common Qt6 QML modules..."
sudo apt install -y qml-module-qtquick-controls qml-module-qtquick-layouts qml-module-qtquick-window qml-module-qt5compat-graphicaleffects qml-module-qtmultimedia

echo "Installing recommended external applications (Chromium, Nautilus)..."
sudo apt install -y chromium-browser nautilus

echo "All specified dependencies and applications have been installed."
echo "Please ensure Flutter SDK is also installed and configured if you haven't already."
