#!/bin/bash
set -e

echo "🚀 Sist OS Deployment Script - Final Architecture"
echo "----------------------------------------------------"

# 1. Flutterビルド
echo "🛠️ Building application..."
flutter build linux
if [ $? -ne 0 ]; then
  echo "❌ Build failed."
  exit 1
fi
echo "✅ Build succeeded!"

# 2. アプリケーション配置
echo "🚚 Deploying application to /opt/sist_ui..."
sudo rm -rf /opt/sist_ui
sudo cp -r build/linux/x64/release/bundle /opt/sist_ui
echo "   Deployment complete."

# 3. Openbox設定配置 (rc.xmlのみ)
echo "⚙️ Deploying Openbox configuration..."
mkdir -p ~/.config/openbox
cp rc.xml ~/.config/openbox/rc.xml
echo "   rc.xml deployed."

echo ""
echo "🎉 Deployment script finished!"
echo "   Please ensure you have configured the system for auto-login."
echo "   Then, reboot your system: sudo reboot"
