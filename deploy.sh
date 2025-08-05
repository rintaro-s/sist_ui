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

# 3. マスターセッションスクリプトを配置
echo "🔑 Deploying the master session script..."
sudo cp sist-session /usr/local/bin/sist-session
sudo chmod +x /usr/local/bin/sist-session
echo "   sist-session deployed."

# 4. ログイン画面用の.desktopファイルを自動生成
echo "🖥️  Creating .desktop file for the login manager..."

# .desktopファイルの内容を定義
DESKTOP_FILE_CONTENT="[Desktop Entry]\nName=Sist OS\nComment=A custom desktop shell by rinta\nExec=/usr/local/bin/sist-session\nType=Application"

# 保護されたディレクトリに安全に書き込む
echo -e "$DESKTOP_FILE_CONTENT" | sudo tee /usr/share/xsessions/sist.desktop > /dev/null
sudo chmod 644 /usr/share/xsessions/sist.desktop
echo "   sist.desktop created successfully."

echo ""
echo "🎉 Deployment script finished!"
echo "   This is the final and definitive architecture."
echo "   Please reboot your system: sudo reboot"