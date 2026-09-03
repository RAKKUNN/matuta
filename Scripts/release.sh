#!/bin/bash
# Matuta 배포판을 만든다: 릴리스 빌드 → Developer ID 서명 → 공증 → 스테이플 → 검증.
#
# 사전 준비 (한 번만):
#   xcrun notarytool store-credentials matuta \
#     --apple-id <애플ID> --team-id VWR66J4U3X
#
# 사용법:
#   ./Scripts/release.sh
set -euo pipefail

cd "$(dirname "$0")/.."

IDENTITY="${MATUTA_IDENTITY:-Developer ID Application: Woojin Im (VWR66J4U3X)}"
PROFILE="${MATUTA_NOTARY_PROFILE:-matuta}"
APP="build/Matuta.app"
ZIP="build/Matuta.zip"

step() { printf "\n\033[1m▸ %s\033[0m\n" "$1"; }

# ── 사전 점검 ────────────────────────────────────────────────
step "사전 점검"

if ! security find-identity -v -p codesigning | grep -qF "$IDENTITY"; then
    echo "✗ 인증서를 찾을 수 없습니다: $IDENTITY" >&2
    echo "  security find-identity -v -p codesigning 으로 확인하세요." >&2
    exit 1
fi
echo "✓ 인증서: $IDENTITY"

if ! xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    echo "✗ 공증 프로필 '$PROFILE' 이 없습니다." >&2
    echo "  xcrun notarytool store-credentials $PROFILE --apple-id <애플ID> --team-id VWR66J4U3X" >&2
    exit 1
fi
echo "✓ 공증 프로필: $PROFILE"

VERSION="$(plutil -extract CFBundleShortVersionString raw Resources/Info.plist)"
echo "✓ 버전: $VERSION"

if [ -n "$(git status --porcelain)" ]; then
    echo "⚠ 커밋되지 않은 변경이 있습니다. 배포판과 저장소가 어긋납니다."
    read -r -p "  그래도 계속할까요? [y/N] " reply
    [ "$reply" = "y" ] || exit 1
fi

# ── 빌드 ─────────────────────────────────────────────────────
step "테스트"
swift test

step "릴리스 빌드"
./Scripts/bundle.sh release

# ── 서명 ─────────────────────────────────────────────────────
# --options runtime (하드닝 런타임)은 공증의 필수 조건이다.
# 하드닝 런타임에서 AppleScript로 다른 앱을 제어하려면
# com.apple.security.automation.apple-events 엔타이틀먼트가 함께 필요하다.
step "Developer ID 서명"
codesign --force --options runtime --timestamp \
    --entitlements Resources/Matuta.entitlements \
    --sign "$IDENTITY" \
    "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"
echo "✓ 서명 검증 통과"

# ── 공증 ─────────────────────────────────────────────────────
step "공증 제출 (몇 분 걸립니다)"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

step "스테이플"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

# ── 최종 검증 ────────────────────────────────────────────────
step "Gatekeeper 판정"
# 다른 맥에서 내려받았을 때와 같은 경로로 평가한다.
spctl --assess --type execute --verbose=4 "$APP"

step "배포용 압축"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "build/Matuta-$VERSION.zip"

printf "\n\033[1;32m완료\033[0m  build/Matuta-%s.zip\n" "$VERSION"
echo "이 파일을 그대로 배포하면 됩니다. 다른 맥에서 내려받아 한 번 열어보세요."
