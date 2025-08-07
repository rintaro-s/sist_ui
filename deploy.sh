#!/bin/bash

set -e

# Build Flutter application
echo "Building Flutter application..."
cd flutter_app
flutter build linux
cd ..

# Generate .desktop file for Flutter Settings App
echo "Generating .desktop file for Flutter Settings App..."
cat <<EOF > debian/sist-settings.desktop
[Desktop Entry]
Name=SIST Settings
Comment=Configure SIST UI settings
Exec=/usr/lib/sist-ui/flutter_app/sist_ui
Icon=/usr/share/sist-ui/theme_assets/icons/logo.png
Terminal=false
Type=Application
Categories=Settings;
EOF

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