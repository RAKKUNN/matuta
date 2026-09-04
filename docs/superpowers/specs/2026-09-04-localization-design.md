# 한국어·영어 인앱 전환 설계

작성일: 2026-09-04
상태: 승인됨 — 구현 계획 작성 대기
기준 커밋: `692aa88` (v1.0.0)

---

## 1. 목표

앱을 한국어와 영어로 쓸 수 있게 한다. 처음 켜면 시스템 언어를 따르고, 설정에서 수동으로 바꿀 수 있으며, **바꾸면 재시작 없이 즉시 반영된다.**

## 2. 결정 사항

| 항목 | 결정 |
|---|---|
| 기본 동작 | 시스템 언어를 따른다 |
| 수동 변경 | 설정에서 `시스템 / 한국어 / English` 중 선택 |
| 반영 시점 | **즉시.** 재시작을 요구하지 않는다 |
| 구현 방식 | 코드 내 타입 안전 카탈로그 (리소스 파일 없음) |
| 코어의 역할 | 판정은 하되 **문장은 만들지 않는다.** 키만 내보낸다 |

### 왜 표준 문자열 카탈로그(`.lproj`)를 쓰지 않는가

애플 표준이지만 이 프로젝트에서는 손해가 크다. `Scripts/bundle.sh`가 `.app`을 손으로 조립하는데, SwiftPM은 리소스를 별도 번들(`Matuta_Matuta.bundle`)로 만든다. 그 번들을 복사하는 단계를 추가해야 하고, **빠뜨리면 로컬에서는 멀쩡한데 배포판에서만 문자열이 깨진다.** 방금 서명·공증까지 통과시킨 파이프라인에 새 실패 지점을 만들 이유가 없다.

언어가 둘뿐이고 번역가 협업 계획도 없다. 언어가 늘어나면 그때 옮겨도 늦지 않다.

## 3. 언어 모델

```swift
// MatutaCore
public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case system
    case korean = "ko"
    case english = "en"
}

/// 실제로 문자열을 고를 때 쓰는 값. `.system`이 여기서 사라진다.
public enum ResolvedLanguage: Sendable {
    case korean
    case english
}
```

`.system`을 `ResolvedLanguage`로 바꾸는 것은 순수 함수다.

```swift
public static func resolve(
    _ setting: AppLanguage,
    preferredLanguages: [String]
) -> ResolvedLanguage
```

`preferredLanguages`는 앱이 `Locale.preferredLanguages`를 넘겨준다. 첫 항목이 `ko`로 시작하면 한국어, 아니면 영어다. **함수 자체는 시스템을 읽지 않으므로 테스트 가능하다.**

## 4. 문자열 카탈로그

```swift
// MatutaCore
public enum LocalizedText: Sendable, Equatable {
    // 인자가 없는 키
    case alarmListTitle
    case addAlarm
    case headphonesConnected
    // …

    // 인자가 있는 키는 연관값으로 받는다
    case lowVolume(percent: Int)
    case snoozeMinutes(Int)
    case automationDenied(target: AutomationTarget)
}

public enum Localizer {
    public static func string(
        _ text: LocalizedText,
        _ language: ResolvedLanguage
    ) -> String
}
```

`Localizer.string`은 거대한 `switch`문 하나다. 못생겼지만 **오타가 컴파일 에러가 되고**, 키가 빠지면 `switch` 비포괄 에러로 잡힌다. 번역 누락이 런타임까지 살아남지 못한다.

인자를 연관값으로 받는 이유는 문자열 보간 순서가 언어마다 다를 수 있기 때문이다. `"볼륨이 낮습니다 (15%)"`와 `"Volume is low (15%)"`를 각각 자연스럽게 쓸 수 있다.

## 5. 코어 변경 — 문장 대신 키

`MatutaCore`에 사용자 노출 한국어 문장이 27개 있다. 이것을 전부 키로 바꾼다.

```swift
// 지금
public struct PreflightWarning {
    public let message: String      // "이어폰 연결됨 (울릴 때 내장 스피커로 자동 전환)"
    public let actionLabel: String? // "스피커로 전환"
}

// 바뀐 뒤
public struct PreflightWarning {
    public let text: LocalizedText          // .headphonesConnected
    public let actionText: LocalizedText?   // .switchToSpeaker
}
```

**판정은 코어에 그대로 남는다.** 어떤 경고가 뜨는지, severity가 무엇인지, 어떤 액션이 붙는지는 여전히 `PreflightEvaluator`가 정한다. 밖으로 나가는 것은 문자열 해석뿐이다.

`PreflightReport.summary`도 `String`에서 `[LocalizedText]`로 바뀐다. 뷰가 해석해서 이어 붙인다.

`Weekday.shortName`(월·화·수…)도 `LocalizedText`를 돌려준다.

### 대상 앱 이름도 번역 대상이다

`AutomationSnapshot.targetName`이 지금 `String`이고, `AutomationPermission.swift:23`이 `"음악"`을 하드코딩한다. 영어로 바꿔도 `"음악 제어 권한이…"`가 그대로 나온다. 이름 자체가 번역 대상이므로 타입으로 바꾼다.

```swift
public enum AutomationTarget: Sendable, Equatable {
    case spotify      // 양쪽 언어 모두 "Spotify"
    case appleMusic   // 한국어 "음악" / English "Music"
}

public struct AutomationSnapshot {
    public let target: AutomationTarget?   // nil이면 자동화가 필요 없는 소스
    public let status: Status
}
```

Spotify는 고유명사라 양쪽에서 같지만, 애플 음악 앱은 macOS 자체가 언어에 따라 `음악`/`Music`으로 다르게 부른다. 우리도 맞춘다.

### 이 변경이 테스트를 더 튼튼하게 만든다

지금 6개 테스트가 한국어 문장에 직접 의존한다.

```swift
#expect(report.warnings[0].message.contains("내장 스피커로 자동 전환"))
#expect(reportLow.warnings.contains { $0.message.contains("볼륨이 낮습니다") })
```

**문구를 다듬기만 해도 깨진다.** 키를 검증하도록 바꾸면 이 취약성이 사라진다.

```swift
#expect(report.warnings[0].text == .headphonesConnected)
```

## 6. 앱 배선

```swift
// Matuta (앱 레이어)
@MainActor @Observable
final class LanguageSetting {
    var selection: AppLanguage {        // UserDefaults에 저장
        didSet { persist() }
    }
    var resolved: ResolvedLanguage {    // 뷰가 읽는 값
        LanguageResolver.resolve(selection, preferredLanguages: Locale.preferredLanguages)
    }
}
```

`LanguageSetting`을 `@Environment`로 뷰 트리에 주입한다. 뷰는 이렇게 쓴다.

```swift
Text(t(.addAlarm))
```

`t(_:)`는 자유 함수가 아니다. 자유 함수는 `@Environment`를 읽을 수 없다. 각 뷰가 환경에서 설정을 받고, `View` 확장이 그것을 사용한다.

```swift
struct SomeView: View {
    @Environment(LanguageSetting.self) private var language

    var body: some View {
        Text(t(.addAlarm))
    }

    private func t(_ key: LocalizedText) -> String {
        Localizer.string(key, language.resolved)
    }
}
```

`t(_:)`를 뷰마다 반복하지 않도록 프로토콜 확장으로 한 번만 정의한다.

```swift
protocol Localizable { var language: LanguageSetting { get } }
extension Localizable {
    func t(_ key: LocalizedText) -> String {
        Localizer.string(key, language.resolved)
    }
}
```

### 즉시 반영이 되는 원리

`LanguageSetting`이 `@Observable`이므로 `selection`이 바뀌면 그것을 읽는 모든 뷰가 다시 그려진다. 다시 그려질 때 `t(...)`가 새 언어로 문자열을 다시 조회한다. **별도의 새로고침 로직이 필요 없다.**

전체화면 오버레이와 나이트스탠드는 별도의 `NSWindow`이므로, 그 창들의 `NSHostingView`에도 같은 `LanguageSetting`을 주입해야 한다. 빠뜨리면 그 두 화면만 언어가 안 바뀐다.

## 7. 설정 화면

macOS 표준대로 `Settings` 씬을 추가한다. `⌘,`로 열리고 메뉴 막대의 `Matuta → 설정…`에도 자동으로 붙는다.

```swift
Settings {
    SettingsView(language: languageSetting)
}
```

v1.1 시점의 설정 항목은 **언어 하나뿐이다.** 세그먼트 컨트롤이나 팝업으로 `시스템 / 한국어 / English`를 고른다. 설정 창을 새로 만드는 김에 다른 항목을 채워 넣고 싶은 유혹이 있지만, 설계 원칙 1("신뢰성은 설정이 아니라 동작이다")에 따라 **항목을 늘리지 않는다.**

선택지 이름은 항상 그 언어 자체로 표기한다 — `한국어`는 어떤 언어 설정에서도 `한국어`로, `English`는 `English`로. 언어 목록에서는 이 편이 알아보기 쉽다. `시스템`/`System`만 현재 언어를 따른다.

## 8. 날짜·시간 형식

시각 표시는 `next.formatted(date: .omitted, time: .shortened)`처럼 시스템 로케일을 따른다. 앱 언어를 English로 바꿨는데 시각이 `오전 7:00`으로 나오면 어색하다.

**앱 언어에 맞춘 `Locale`을 포맷터에 명시적으로 넘긴다.**

```swift
next.formatted(.dateTime.hour().minute().locale(language.locale))
```

`ResolvedLanguage`가 `locale` 프로퍼티(`ko_KR` / `en_US`)를 제공한다. 12/24시간 표기가 언어에 따라 달라지는데, 이는 의도한 동작이다.

## 9. Info.plist 문자열

`NSAppleEventsUsageDescription`은 **macOS가 권한 대화상자에 띄우는 문자열이라 앱 설정이 아니라 시스템 언어를 따른다.** 이것만 제대로 현지화하려면 `InfoPlist.strings`가 필요하고, 그러면 §2에서 피한 리소스 번들 문제가 다시 들어온다.

**한 문자열에 두 언어를 같이 적는다.**

```
알람 시각에 선택하신 음악을 재생하기 위해 필요합니다. / Needed to play your chosen music at alarm time.
```

우아하지 않지만, 영어권 사용자가 첫 실행에서 마주치는 유일한 지점이고 리소스 배선을 들여올 만큼의 가치는 없다.

## 10. 테스트 전략

**코어 (순수, 자동화):**
- `LanguageResolver.resolve` — `preferredLanguages`가 `["ko-KR"]`, `["en-US"]`, `["ja-JP"]`, `[]`일 때 각각. `.korean`/`.english` 선택이 시스템을 무시하는지
- `Localizer.string` — **모든 `LocalizedText` 케이스가 두 언어 모두에서 빈 문자열이 아닌지.** `CaseIterable`이 불가능한 연관값 케이스는 대표값을 넣어 직접 나열한다
- 인자가 있는 키가 값을 실제로 담는지 (`lowVolume(percent: 15)` → 양쪽 언어 모두 `"15"` 포함)
- 기존 `PreflightEvaluator` 테스트를 문장 검증에서 **키 검증으로 교체**

**수동 확인:**
- 설정에서 언어를 바꿨을 때 목록 창·편집 시트·메뉴바가 **즉시** 바뀌는지
- 나이트스탠드와 알람 오버레이도 바뀌는지 (별도 `NSWindow`라 누락되기 쉬움)
- 영어로 바꿨을 때 시각이 `7:00 AM`으로 나오는지
- 영어에서 글자가 길어져 잘리는 곳이 없는지 (요일 칩, 뱃지 캡슐이 위험)

## 11. 구현 순서

한 번에 140개를 옮기면 중간 상태가 컴파일되지 않는다. 네 단계로 나눈다. 각 단계가 끝날 때마다 빌드와 테스트가 통과해야 한다.

| 단계 | 내용 | 끝났을 때 |
|---|---|---|
| 1 | `AppLanguage`·`ResolvedLanguage`·`LanguageResolver`·`Localizer` 뼈대와 테스트 | 코어에 번역 기반이 생긴다. 아직 아무도 안 쓴다 |
| 2 | 코어 27개 문자열을 키로 교체, 기존 테스트를 키 검증으로 전환 | 코어가 언어 중립이 된다 |
| 3 | `LanguageSetting`·설정 화면·환경 주입, 앱 113개 문자열 교체 | 토글이 실제로 동작한다 |
| 4 | 날짜·시간 로케일, Info.plist 이중 표기, 영어 화면 눈 검사 | 마무리 |

## 12. 범위 밖

- 3번째 언어. 구조는 열려 있지만 이번에 넣지 않는다
- README·릴리스 노트·설계 문서의 영어화
- 오른쪽에서 왼쪽으로 쓰는 언어(RTL) 대응
- 설정 창에 언어 외의 항목 추가

## 13. 리스크

| 리스크 | 대응 |
|---|---|
| 별도 `NSWindow`(오버레이·나이트스탠드)에 환경 주입 누락 | 수동 확인 항목에 명시. 두 창 모두 같은 `LanguageSetting` 인스턴스를 받게 한다 |
| 영어 문자열이 길어 UI가 잘림 | 요일 칩과 뱃지는 고정폭이 많다. 영어로 바꾼 상태에서 전 화면을 눈으로 확인한다 |
| 키 140개짜리 `switch`가 비대해짐 | `Localizer`를 화면 단위 파일로 나눈다 (`Localizer+Alarm.swift` 등). 한 파일이 커지지 않게 한다 |
| 번역 누락 | `switch` 비포괄이 컴파일 에러가 되고, 전 케이스 비어있음 검사 테스트가 잡는다 |
| 기존 테스트 6건이 깨짐 | 의도된 변경이다. 키 검증으로 교체하면서 더 튼튼해진다 |
