#!/bin/bash

set -e

echo "🚀 Sist OS Deployment Script - Final Edition"
echo "----------------------------------------------------"

# 1. Flutter Build
echo "📦 Fetching packages..."
flutter pub get
echo "🛠️ Building application..."
flutter build linux
if [ $? -ne 0 ]; then
  echo "❌ Build failed."
  echo "   Aborting deployment process."
  exit 1
fi
echo "✅ Build succeeded!"

# 2. Deploy Application
echo "🚚 Deploying application to /opt/sist_ui..."
if [ -d "/opt/sist_ui" ]; then
  sudo rm -rf "/opt/sist_ui"
fi
sudo cp -r build/linux/x64/release/bundle "/opt/sist_ui"
echo "   Deployment complete."

# 3. Deploy Openbox Configuration
echo "⚙️ Deploying Openbox configuration..."
mkdir -p ~/.config/openbox
cp rc.xml ~/.config/openbox/rc.xml
cp autostart ~/.config/openbox/autostart
chmod +x ~/.config/openbox/autostart

# 4. Fix ownership of config directory
echo "🔐 Fixing ownership of config directory..."
sudo chown -R $USER:$USER /home/$USER/.config

# 5. Deploy Login Session Script
echo "🔑 Deploying login session script..."
sudo cp sist-session /usr/local/bin/sist-session
sudo chmod +x /usr/local/bin/sist-session

echo ""
echo "🎉 All processes completed successfully!"
echo "   Please reboot your system to apply changes: sudo reboot"
echo "----------------------------------------------------"