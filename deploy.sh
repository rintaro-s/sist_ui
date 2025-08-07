#!/bin/bash

set -e

# Build Flutter application
echo "Building Flutter application..."
cd flutter_app
flutter build linux
cd ..

# Build Qt/QML shell
echo "Building Qt/QML shell..."
mkdir -p shell/build
cd shell/build
qmake6 ../shell.pro
make
cd ../..

# Create .deb package
echo "Creating .deb package..."
dpkg-buildpackage -us -uc

echo "SIST UI build and .deb package creation complete."

# To run the custom session (for testing purposes, not part of .deb install)
# echo "To run the custom session, execute:"
# echo "./sist-session"