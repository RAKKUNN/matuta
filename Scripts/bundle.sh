#!/bin/bash
# Matuta.app 번들을 조립한다. SwiftUI 앱은 번들 안에서 실행해야
# Dock 아이콘과 창 활성화가 정상 동작한다.
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
swift build -c "$CONFIG" --product Matuta

BIN="$(swift build -c "$CONFIG" --product Matuta --show-bin-path)/Matuta"
APP="build/Matuta.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Matuta"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# 로컬 실행용 임시 서명. 배포용 Developer ID 서명은 나중 단계에서 다룬다.
codesign --force --sign - "$APP"

echo "빌드 완료: $APP"
