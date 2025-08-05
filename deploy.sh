#!/bin/bash
set -e

echo "🚀 Sist OS Deployment Script - Final Edition"
echo "----------------------------------------------------"

# Flutterビルド
echo "🛠️ Building application..."
flutter build linux
if [ $? -ne 0 ]; then
  echo "❌ Build failed."
  exit 1
fi
echo "✅ Build succeeded!"

# アプリケーション配置
echo "🚚 Deploying application to /opt/sist_ui..."
sudo rm -rf /opt/sist_ui
sudo cp -r build/linux/x64/release/bundle /opt/sist_ui
echo "   Deployment complete."

# Openbox設定配置 (rc.xmlのみ)
echo "⚙️ Deploying Openbox configuration..."
mkdir -p ~/.config/openbox
cp rc.xml ~/.config/openbox/rc.xml
echo "   rc.xml deployed."

# ログインセッションスクリプト配置
echo "🔑 Deploying login session script..."
sudo cp sist-session /usr/local/bin/sist-session
sudo chmod +x /usr/local/bin/sist-session
echo "   sist-session deployed."

echo ""
echo "🎉 Deployment script finished!"
echo "   Please ensure you have created and configured ~/.xinitrc correctly."
echo "   Then, reboot your system: sudo reboot"