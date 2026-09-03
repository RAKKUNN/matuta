# 1.0.0 배포 전 최종 검토

작성일: 2026-09-03
대상: `79f34a8` (커밋 27개)
판정: **현 상태로는 배포 불가.** 차단 항목 4건을 먼저 해결해야 한다.

---

## 0. 건강한 것

- `swift test` **58개 전부 통과**
- `swift build -c release` 경고 없이 통과
- 작업 트리 깨끗, 커밋 27개
- 코어 판정 로직이 `MatutaCore`에 모여 있고 테스트가 지킨다
- 앱 아이콘이 `CFBundleIconFile`로 정상 배선되어 번들에 포함된다

코드 자체는 배포할 만한 상태다. 아래는 전부 **포장과 배포 절차**의 문제다.

---

## 1. 배포 차단 항목

### A. 임시(ad-hoc) 서명 — 남이 열 수 없다

```
$ codesign -dv build/Matuta.app
Signature=adhoc
TeamIdentifier=not set
```

`Scripts/bundle.sh:27`이 `codesign --force --sign -`, 즉 임시 서명을 한다. 스크립트 주석에도 "배포용 Developer ID 서명은 나중 단계에서 다룬다"고 적혀 있다. **그 나중이 지금이다.**

임시 서명한 앱을 다른 사람이 내려받으면 Gatekeeper가 막는다. 설계 문서 §3.3이 정한 배포 방식은 "Developer ID 서명 + 공증, 비샌드박스, 직접 배포"다.

필요한 것:

1. Apple Developer Program 등록 (연 $99). **이게 없으면 정식 배포가 불가능하다.** 개인적으로만 쓸 거라면 임시 서명으로 충분하니, 여기서 배포 여부 자체를 다시 판단해도 된다
2. Developer ID Application 인증서 발급
3. 하드닝 런타임을 켜고 타임스탬프를 넣어 서명
4. 공증(notarize) 후 스테이플

```bash
# 3. 서명 (하드닝 런타임 필수 — 공증 조건)
codesign --force --options runtime --timestamp \
  --entitlements Resources/Matuta.entitlements \
  --sign "Developer ID Application: <이름> (<TEAMID>)" \
  build/Matuta.app

# 4. 공증
ditto -c -k --keepParent build/Matuta.app build/Matuta.zip
xcrun notarytool submit build/Matuta.zip \
  --apple-id <애플ID> --team-id <TEAMID> --password <앱 암호> --wait
xcrun stapler staple build/Matuta.app
```

### B. Apple Events 권한 설명 누락 — Spotify·Apple Music 알람이 안 울린다

`SpotifySource.swift`와 `AppleMusicSource.swift`가 `NSAppleScript`로 외부 앱을 제어한다.

```swift
// SpotifySource.swift:40
if let script = NSAppleScript(source: scriptSource) {
    var errorInfo: NSDictionary?
    script.executeAndReturnError(&errorInfo)
}
```

macOS Mojave부터 다른 앱에 Apple Event를 보내려면 **`NSAppleEventsUsageDescription`이 Info.plist에 있어야 한다.** 지금 없다. 키가 없으면 시스템이 요청을 거부한다(-1743).

그리고 **하드닝 런타임을 켜면 조건이 하나 더 붙는다** — `com.apple.security.automation.apple-events` 엔타이틀먼트도 필요하다. A항목을 처리하면서 이걸 빠뜨리기 쉽다. 둘 다 있어야 한다.

`Resources/Info.plist`에 추가:

```xml
<key>NSAppleEventsUsageDescription</key>
<string>알람 시각에 Spotify나 음악 앱에서 선택한 곡을 재생하기 위해 필요합니다.</string>
```

`Resources/Matuta.entitlements` (새로 만들 것):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

**임시 서명이 이 문제를 악화시킨다.** TCC(권한 허용 기록)는 코드 서명을 기준으로 앱을 식별한다. 임시 서명은 빌드할 때마다 서명이 달라지므로, 사용자가 자동화 권한을 허용해도 **업데이트할 때마다 다시 물어본다.** 안정적인 Developer ID 서명이 있어야 허용이 유지된다. A와 B는 사실상 한 묶음이다.

한 가지 다행인 점은 Spotify·웹 소스가 `needsBackupTone = true`라, 자동화가 거부돼도 **백업음은 울린다.** 기상 실패로 이어지지는 않는다. 다만 사용자가 고른 음악은 안 나온다.

### C. 버전이 0.1.0이다

```xml
<key>CFBundleShortVersionString</key>
<string>0.1.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

1.0.0으로 올리고 `CFBundleVersion`도 함께 올린다. 그리고 git 태그를 붙인다.

```bash
git tag -a v1.0.0 -m "Matuta 1.0.0"
```

### D. 라이선스 파일이 없다

설계 문서는 **무료/오픈소스 배포**를 전제한다. 그런데 저장소에 `LICENSE`가 없다.

라이선스가 없으면 법적으로 **누구도 이 코드를 사용·복제·배포할 권리가 없다.** 공개 저장소에 올려두는 것만으로는 사용 허가가 되지 않는다. MIT나 Apache-2.0 중 하나를 고르면 된다 — 이 프로젝트 성격이면 MIT가 무난하다.

---

## 2. 출시 품질 (차단은 아니지만 고치는 게 맞다)

### E. README가 사실과 다르다

```
현재 이 저장소에는 **설계 문서만** 들어 있다. 코드는 아직 없다.
```

커밋 27개에 동작하는 앱이 있는데 README는 아직 코드가 없다고 말한다. 개발 단계 표도 전부 "계획 완료 / 계획 미작성"에 멈춰 있다. **공개 저장소의 첫인상이 이것이다.**

설치 안내도 없다. 배포한다면 최소한 이게 있어야 한다:

- 무엇을 하는 앱인가 (지금 잘 적혀 있음)
- 스크린샷 한 장
- 다운로드 링크 또는 소스 빌드 방법
- macOS 14.0 이상 필요
- 처음 실행할 때 자동화 권한을 묻는다는 안내

### F. `bundle.sh`의 기본값이 debug다

```bash
CONFIG="${1:-debug}"
```

`./Scripts/bundle.sh`를 인자 없이 실행하면 **디버그 빌드**가 나온다. 배포판을 만들려면 `./Scripts/bundle.sh release`를 쳐야 하는데, 이걸 잊으면 디버그 바이너리를 배포하게 된다.

배포용 스크립트의 기본값은 release여야 한다. 아니면 `Scripts/release.sh`를 따로 두고 서명·공증까지 한 번에 처리하는 편이 안전하다.

### G. AppleScript 오류를 삼킨다

```swift
var errorInfo: NSDictionary?
script.executeAndReturnError(&errorInfo)   // errorInfo를 아무도 안 본다
```

자동화가 거부되거나 Spotify가 꺼져 있어도 앱은 알지 못한다. `play()`가 던지지 않으므로 `PlaybackChain`은 주 소스가 성공했다고 믿는다.

백업음 덕분에 기상은 보장되지만, **사용자는 왜 자기 음악이 안 나왔는지 영원히 모른다.** `errorInfo`가 있으면 던지도록 바꾸면, 프리플라이트가 "Spotify 자동화 권한이 없습니다"를 미리 경고할 수 있다. 이 앱의 정체성과 직결되는 부분이다.

---

## 3. 배포 전 반드시 실제로 해봐야 하는 것

코드로는 확인이 불가능하다.

- [ ] **스누즈를 걸고 맥을 재운 뒤 실제로 울리는지** — 제품의 핵심 약속인데 여전히 실측된 적이 없다
- [ ] 알람을 걸고 맥을 재운 뒤 실제로 깨어나 울리는지 (덮개를 닫은 상태, 전원 연결/배터리 각각)
- [ ] 다른 계정이나 다른 맥에서 내려받아 실행 — Gatekeeper 통과 여부
- [ ] 첫 실행 시 자동화 권한 대화상자가 뜨는지, 허용 후 Spotify 알람이 실제로 재생되는지
- [ ] 알람 파일이 없는 깨끗한 상태에서 첫 실행

---

## 4. 권장 순서

1. **배포할 것인지 먼저 정한다.** Apple Developer Program 연 $99가 들고, 안 하면 남이 못 연다. 개인용이면 여기서 멈춰도 된다
2. LICENSE 추가, 버전 1.0.0, README 갱신 (차단 C·D·E — 돈이 안 드는 것부터)
3. `NSAppleEventsUsageDescription` + 엔타이틀먼트 추가 (차단 B)
4. AppleScript 오류 전파 + 프리플라이트 연동 (품질 G)
5. `Scripts/release.sh`로 서명·공증 자동화 (차단 A, 품질 F)
6. 3절의 실측 항목 전부 통과
7. `v1.0.0` 태그, 릴리스 노트, 배포
