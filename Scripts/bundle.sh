#!/bin/bash
# Matuta.app 번들을 조립한다. SwiftUI 앱은 번들 안에서 실행해야
# Dock 아이콘과 창 활성화가 정상 동작한다.
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
swift build -c "$CONFIG" --product Matuta

BIN="$(swift build -c "$CONFIG" --product Matuta --show-bin-path)/Matuta"
APP="build/Matuta.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Matuta"
cp Resources/Info.plist "$APP/Contents/Info.plist"

if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi
if [ -f "Resources/logo.png" ]; then
    cp Resources/logo.png "$APP/Contents/Resources/logo.png"
fi

# 로컬 실행용 임시 서명. 배포판은 Scripts/release.sh 가 Developer ID로 서명한다.
# 엔타이틀먼트를 함께 넣어 로컬 동작이 배포판과 같아지게 한다.
codesign --force --entitlements Resources/Matuta.entitlements --sign - "$APP"

echo "빌드 완료: $APP"
