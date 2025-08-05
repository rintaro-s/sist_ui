#!/bin/bash

# Openboxウィンドウマネージャをバックグラウンドで起動
openbox &

# Flutterアプリ（デスクトップシェル）を起動
# このプロセスが終了すると、セッションも終了する
exec /opt/sist_ui/sist_ui