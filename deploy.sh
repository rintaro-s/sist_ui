#!/bin/bash

# --- Sist OS 自動ビルド＆配置スクリプト ---
# エラーが発生した場合は、その時点でスクリプトを停止します
set -e

echo "🚀 Sist OS Deployment Script - Memento Mori Edition"
echo "----------------------------------------------------"

# 1. Flutterプロジェクトの依存関係を取得
echo "📦 パッケージを取得しています..."
flutter pub get

# 2. Flutterアプリをビルド
# ここでは 'set -e' を一時的に無効にし、ビルド失敗を個別にハンドルします
set +e
echo "🛠️ アプリケーションをビルド中..."
flutter build linux
BUILD_STATUS=$? # 直前のコマンドの終了ステータスを取得
set -e

# 3. ビルドの成否をチェック
if [ $BUILD_STATUS -ne 0 ]; then
  # 0以外はエラーを意味する
  echo "❌ ビルドに失敗しました。(終了コード: $BUILD_STATUS)"
  echo "   配置プロセスを中断します。"
  exit 1
else
  echo "✅ ビルド成功！"
fi

# 4. アプリケーション本体を配置
echo "🚚 アプリケーションを /opt/sist_ui に配置しています..."
# 古いバージョンがあれば削除
if [ -d "/opt/sist_ui" ]; then
  sudo rm -rf /opt/sist_ui
fi
# ビルドしたアプリ一式をコピー
sudo cp -r build/linux/x64/release/bundle /opt/sist_ui
echo "   配置完了。"

# 5. Openbox設定ファイルを配置
echo "⚙️ Openbox設定を配置しています..."
# 設定ディレクトリがなければ作成
mkdir -p ~/.config/openbox

# rc.xml をコピー
if [ -f "rc.xml" ]; then
  cp rc.xml ~/.config/openbox/rc.xml
  echo "   ~/.config/openbox/rc.xml にコピーしました。"
else
  echo "   ⚠️  警告: rc.xml がプロジェクト内に見つかりません。"
fi

# autostart スクリプトをコピー
if [ -f "autostart" ]; then
  cp autostart ~/.config/openbox/autostart
  chmod +x ~/.config/openbox/autostart
  echo "   ~/.config/openbox/autostart にコピーし、実行権限を付与しました。"
else
  echo "   ⚠️  警告: autostart がプロジェクト内に見つかりません。"
fi

# 6. ログインセッション用スクリプトを配置
echo "🔑 ログインセッションスクリプトを配置しています..."
if [ -f "sist-session" ]; then
  sudo cp sist-session /usr/local/bin/sist-session
  sudo chmod +x /usr/local/bin/sist-session
  echo "   /usr/local/bin/sist-session にコピーし、実行権限を付与しました。"
else
  echo "   ⚠️  警告: sist-session がプロジェクト内に見つかりません。"
fi

echo ""
echo "🎉 すべてのプロセスが正常に完了しました！"
echo "   システムを再起動して変更を適用してください: sudo reboot"
echo "----------------------------------------------------"
