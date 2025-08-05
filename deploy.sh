#!/bin/bash

# --- Sist OS 自動ビルド＆配置スクリプト ---
# エラーが発生した場合は、その時点でスクリプトを停止します
set -e

echo "🚀 Sist OS Deployment Script - Memento Mori Edition"
echo "----------------------------------------------------"

# 1. Get Flutter project dependencies
echo "📦 Fetching packages..."
flutter pub get

# 2. Build Flutter app
# ここでは 'set -e' を一時的に無効にし、ビルド失敗を個別にハンドルします
set +e
echo "🛠️ Building application..."
flutter build linux
BUILD_STATUS=$? # 直前のコマンドの終了ステータスを取得
set -e

# 3. Check build result
if [ $BUILD_STATUS -ne 0 ]; then
  # 0以外はエラーを意味する
  echo "❌ Build failed. (Exit code: $BUILD_STATUS)"
  echo "   Deployment process aborted."
  exit 1
else
  echo "✅ Build succeeded!"
fi

# 4. Deploy application bundle
echo "🚚 Deploying application to /opt/sist_ui..."
# 古いバージョンがあれば削除
if [ -d "/opt/sist_ui" ]; then
  sudo rm -rf /opt/sist_ui
fi
# ビルドしたアプリ一式をコピー
sudo cp -r build/linux/x64/release/bundle /opt/sist_ui
echo "   Deployment complete."

# 5. Deploy Openbox configuration files
echo "⚙️ Deploying Openbox configuration..."
# 設定ディレクトリがなければ作成
mkdir -p ~/.config/openbox

# rc.xml をコピー
if [ -f "rc.xml" ]; then
  cp rc.xml ~/.config/openbox/rc.xml
  echo "   Copied to ~/.config/openbox/rc.xml."
else
  echo "   ⚠️  Warning: rc.xml not found in project."
fi

# autostart スクリプトをコピー
if [ -f "autostart" ]; then
  cp autostart ~/.config/openbox/autostart
  chmod +x ~/.config/openbox/autostart
  echo "   Copied to ~/.config/openbox/autostart and set executable."
else
  echo "   ⚠️  Warning: autostart not found in project."
fi

# 6. Deploy login session script
echo "🔑 Deploying login session script..."
if [ -f "sist-session" ]; then
  sudo cp sist-session /usr/local/bin/sist-session
  sudo chmod +x /usr/local/bin/sist-session
  echo "   Copied to /usr/local/bin/sist-session and set executable."
else
  echo "   ⚠️  Warning: sist-session not found in project."
fi

echo ""
echo "🎉 All processes completed successfully!"
echo "   Please reboot your system to apply changes: sudo reboot"
echo "----------------------------------------------------"
