#!/bin/bash
set -e

echo "🚀 Sist OS Deployment Script - Wayland/Cage Architecture"
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

# 3. 新しいセッションスクリプトを配置
echo "🔑 Deploying the new session script..."
sudo cp sist-session /usr/local/bin/sist-session
sudo chmod +x /usr/local/bin/sist-session
echo "   sist-session deployed."

echo ""
echo "🎉 Deployment script finished!"
echo "   This is the new, simpler, and more robust architecture."
echo "   Please reboot your system: sudo reboot"