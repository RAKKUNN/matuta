# Daybreak 1단계 (뼈대) 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 정해둔 시각에 실제로 소리를 내고 스페이스바로 꺼지는, 매일 쓸 수 있는 macOS 알람앱을 만든다.

**Architecture:** 순수 로직(모델·시각 계산·영속화·스케줄링·톤 생성)을 `DaybreakCore` 라이브러리에 몰아넣고 `swift test`로 전부 검증한다. SwiftUI 앱(`Daybreak`)은 그 위에 얹는 얇은 껍데기이며 수동으로 확인한다. Xcode 프로젝트 파일 없이 순수 SwiftPM으로 구성하고, `.app` 번들은 셸 스크립트로 조립한다 — 전 과정이 터미널에서 재현 가능해야 하기 때문이다.

**Tech Stack:** Swift 6.3, SwiftPM (swift-tools-version 6.0), SwiftUI, AppKit (오버레이 창), AVFAudio (톤 생성), swift-testing (`import Testing`)

## Global Constraints

- 배포 대상: macOS 14.0 이상 (`platforms: [.macOS(.v14)]`)
- **비샌드박스**. entitlement 파일을 만들지 않는다
- 설계 문서: `docs/superpowers/specs/2026-09-02-macos-alarm-app-design.md`. 아래 원칙을 어기는 코드는 이 계획에 없어야 한다
  - 신뢰성은 설정이 아니라 동작이다 — 출력 기기·폴백·절전 예약을 토글로 노출하지 않는다
  - 알람별 동작 설정은 볼륨·페이드인·스누즈 셋뿐이다
  - 첫 실행 시 빈 화면을 보여주지 않는다
- **스페이스바 = 완전히 끄기. 스누즈는 마우스 클릭으로만.** 오버레이에서 다른 키는 전부 무시한다
- 알람 저장 위치: `~/Library/Application Support/Daybreak/alarms.json`
- 이 계획의 범위는 설계 문서 §11의 **0단계 + 1단계**뿐이다. 2단계(소스 6종·옴니박스)와 3단계(AudioGuard·Preflight·나이트스탠드)는 별도 계획으로 쓴다. `SoundSourceRef`는 6종 전부 정의하되 **1단계에서 실제로 재생되는 것은 `.builtIn`뿐이다**
- 모든 사용자 노출 문자열은 한국어

## 파일 구조

| 파일 | 책임 |
|---|---|
| `Package.swift` | 패키지 정의 |
| `Sources/DaybreakCore/Weekday.swift` | 요일. `Calendar`의 weekday 값(일=1)과 일치 |
| `Sources/DaybreakCore/SoundSourceRef.swift` | 사운드 소스 식별자 (데이터만) |
| `Sources/DaybreakCore/Alarm.swift` | 알람 모델 |
| `Sources/DaybreakCore/WallClock.swift` | 현재 시각 주입용 프로토콜 |
| `Sources/DaybreakCore/NextOccurrence.swift` | 다음 발생 시각 계산 (순수 함수) |
| `Sources/DaybreakCore/AlarmStore.swift` | JSON 영속화 |
| `Sources/DaybreakCore/AlarmTimer.swift` | 타이머 추상화 |
| `Sources/DaybreakCore/Scheduler.swift` | 다음 알람 선택 + 발화 |
| `Sources/DaybreakCore/TonePattern.swift` | 톤 파형 생성 (순수 함수) |
| `Sources/Daybreak/DaybreakApp.swift` | 앱 진입점, 씬 구성 |
| `Sources/Daybreak/AlarmListModel.swift` | 목록 창의 상태 |
| `Sources/Daybreak/AlarmListView.swift` | 알람 목록 창 |
| `Sources/Daybreak/AlarmEditView.swift` | 알람 편집 시트 |
| `Sources/Daybreak/TonePlayer.swift` | `TonePattern` → 실제 소리 (AVFAudio) |
| `Sources/Daybreak/AlarmOverlayWindow.swift` | 전체화면 창 + 키 처리 |
| `Sources/Daybreak/AlarmOverlayView.swift` | 오버레이 내용 |
| `Tests/DaybreakCoreTests/*` | 위 순수 로직 테스트 |
| `Scripts/bundle.sh` | `.app` 조립 |
| `Resources/Info.plist` | 번들 메타데이터 |

---

## Task 0: 절전 깨우기 권한 스파이크

설계 문서 §9의 미해결 사항을 제일 먼저 없앤다. `IOPMSchedulePowerEvent`가 관리자 권한을 요구하는지에 따라 온보딩 설계가 갈린다. **이 태스크는 실험이므로 TDD를 적용하지 않는다.** 결과를 문서로 남기는 것이 산출물이다.

**Files:**
- Create: `Spikes/power-wake-spike.swift`
- Create: `docs/superpowers/spikes/2026-09-02-power-wake.md`

**Interfaces:**
- Consumes: 없음
- Produces: 없음 (조사 결과만. 3단계 계획이 이 문서를 읽는다)

- [ ] **Step 1: 스파이크 코드 작성**

```swift
// Spikes/power-wake-spike.swift
// 실행: swift Spikes/power-wake-spike.swift
import Foundation
import IOKit
import IOKit.pwr_mgt   // 이게 없으면 IOPMSchedulePowerEvent를 못 찾는다

let wakeAt = Date().addingTimeInterval(120)

let result = IOPMSchedulePowerEvent(
    wakeAt as CFDate,
    "com.daybreak.spike" as CFString,
    kIOPMAutoWakeOrPowerOn as CFString
)

if result == kIOReturnSuccess {
    print("성공: 권한 없이 전원 이벤트 예약됨 (\(wakeAt))")
} else {
    print("실패: IOReturn=\(String(format: "0x%08X", result))")
    if result == kIOReturnNotPrivileged {
        print("→ kIOReturnNotPrivileged: 관리자 권한이 필요함")
    }
}
```

- [ ] **Step 2: 권한 없이 실행**

Run: `swift Spikes/power-wake-spike.swift`

두 결과 중 하나가 나온다. 출력을 그대로 기록한다.

- [ ] **Step 3: 예약이 실제로 걸렸는지 확인**

Run: `pmset -g sched`

Expected: 2단계가 성공했다면 `wakeorpoweron at ...` 항목에 방금 시각이 보인다. 안 보이면 API가 성공을 반환했어도 실제로는 등록되지 않은 것이므로 실패로 간주한다.

- [ ] **Step 4: 예약 취소**

```bash
sudo pmset schedule cancelall
pmset -g sched
```

Expected: 목록이 비어 있다.

- [ ] **Step 5: 결과를 문서로 남긴다**

`docs/superpowers/spikes/2026-09-02-power-wake.md`에 아래 형식으로 기록한다. `<>` 안은 실제 관찰한 값으로 채운다.

```markdown
# 스파이크: 절전 깨우기 권한

날짜: 2026-09-02
질문: `IOPMSchedulePowerEvent`가 관리자 권한 없이 동작하는가?

## 결과
- 반환값: <kIOReturnSuccess 또는 0x... >
- `pmset -g sched`에 등록됨: <예 / 아니오>

## 결론
<권한 불필요 → 3단계에서 PowerDaybreak가 직접 호출한다.>
<또는: 권한 필요 → 설계 문서 §9의 대안 (a) 헬퍼 설치 / (b) 절전 방지 대체 중 하나를 3단계 계획에서 선택한다. 어느 쪽을 권하는지와 이유를 여기 적는다.>
```

- [ ] **Step 6: 커밋**

```bash
git init
git add Spikes/ docs/
git commit -m "spike: 절전 깨우기 권한 요구사항 확인"
```

---

## Task 1: 패키지 뼈대와 Alarm 모델

**Files:**
- Create: `Package.swift`
- Create: `Sources/DaybreakCore/Weekday.swift`
- Create: `Sources/DaybreakCore/SoundSourceRef.swift`
- Create: `Sources/DaybreakCore/Alarm.swift`
- Test: `Tests/DaybreakCoreTests/AlarmTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `enum Weekday: Int, Codable, CaseIterable, Sendable` — `.sunday = 1` … `.saturday = 7`
  - `enum SoundSourceRef: Codable, Equatable, Sendable` — `.builtIn(name: String)`, `.localFile(bookmark: Data)`, `.streamURL(URL)`, `.appleMusic(id: String)`, `.spotify(uri: String)`, `.web(URL)`
  - `struct Alarm: Codable, Identifiable, Equatable, Sendable` — 프로퍼티 `id, hour, minute, weekdays, label, source, volume, fadeIn, snoozeMinutes, isEnabled`
  - `Alarm.init(id:hour:minute:weekdays:label:source:volume:fadeIn:snoozeMinutes:isEnabled:)` — `id`는 `UUID()`, `weekdays`는 `[]`, `label`은 `nil`, `source`는 `.builtIn(name: "Radar")`, `volume`은 `0.7`, `fadeIn`은 `true`, `snoozeMinutes`는 `9`, `isEnabled`는 `true`가 기본값

- [ ] **Step 1: 패키지 정의 작성**

`Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Daybreak",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "DaybreakCore", targets: ["DaybreakCore"]),
        .executable(name: "Daybreak", targets: ["Daybreak"]),
    ],
    targets: [
        .target(name: "DaybreakCore"),
        .executableTarget(name: "Daybreak", dependencies: ["DaybreakCore"]),
        .testTarget(name: "DaybreakCoreTests", dependencies: ["DaybreakCore"]),
    ]
)
```

`Sources/Daybreak/`가 아직 비어 있으면 빌드가 실패하므로, 자리를 채우는 파일을 하나 만든다.

`Sources/Daybreak/DaybreakApp.swift`:

```swift
// Task 6에서 실제 앱으로 바뀐다.
import Foundation

@main
struct DaybreakApp {
    static func main() {
        print("Daybreak")
    }
}
```

- [ ] **Step 2: 실패하는 테스트 작성**

`Tests/DaybreakCoreTests/AlarmTests.swift`:

```swift
import Testing
import Foundation
@testable import DaybreakCore

@Test("기본값으로 알람을 만들면 평일 반복 없이 켜져 있다")
func alarmDefaults() {
    let alarm = Alarm(hour: 7, minute: 0)

    #expect(alarm.hour == 7)
    #expect(alarm.minute == 0)
    #expect(alarm.weekdays.isEmpty)
    #expect(alarm.source == .builtIn(name: "Radar"))
    #expect(alarm.volume == 0.7)
    #expect(alarm.fadeIn == true)
    #expect(alarm.snoozeMinutes == 9)
    #expect(alarm.isEnabled == true)
}

@Test("알람을 JSON으로 저장했다 읽으면 그대로 복원된다")
func alarmCodableRoundTrip() throws {
    let original = Alarm(
        hour: 8,
        minute: 15,
        weekdays: [.monday, .wednesday, .friday],
        label: "운동",
        source: .spotify(uri: "spotify:playlist:abc123"),
        volume: 0.4,
        fadeIn: false,
        snoozeMinutes: nil,
        isEnabled: false
    )

    let data = try JSONEncoder().encode(original)
    let restored = try JSONDecoder().decode(Alarm.self, from: data)

    #expect(restored == original)
}

@Test("Weekday 값은 Calendar의 weekday 성분과 일치한다")
func weekdayMatchesCalendar() {
    #expect(Weekday.sunday.rawValue == 1)
    #expect(Weekday.saturday.rawValue == 7)
    #expect(Weekday.allCases.count == 7)
}
```

- [ ] **Step 3: 테스트가 실패하는지 확인**

Run: `swift test`

Expected: FAIL — `cannot find 'Alarm' in scope`, `cannot find 'Weekday' in scope`

- [ ] **Step 4: 최소 구현 작성**

`Sources/DaybreakCore/Weekday.swift`:

```swift
import Foundation

/// `Calendar`의 `weekday` 성분과 같은 값을 쓴다 (일요일 = 1).
public enum Weekday: Int, Codable, CaseIterable, Sendable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    /// 목록 창과 편집 시트에 쓰는 한 글자 표기.
    public var shortName: String {
        switch self {
        case .sunday: "일"
        case .monday: "월"
        case .tuesday: "화"
        case .wednesday: "수"
        case .thursday: "목"
        case .friday: "금"
        case .saturday: "토"
        }
    }

    /// 편집 시트에 월요일부터 표시하기 위한 순서.
    public static let displayOrder: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]
}
```

`Sources/DaybreakCore/SoundSourceRef.swift`:

```swift
import Foundation

/// 알람이 무엇으로 울릴지를 가리키는 식별자. 재생 방법은 갖고 있지 않다.
///
/// 1단계에서 실제로 재생되는 것은 `.builtIn`뿐이다. 나머지는 2단계에서
/// `SoundSource` 프로토콜 구현이 붙는다. 모델을 나중에 고치지 않으려고
/// 여섯 가지를 지금 전부 정의해둔다.
public enum SoundSourceRef: Codable, Equatable, Sendable {
    case builtIn(name: String)
    case localFile(bookmark: Data)
    case streamURL(URL)
    case appleMusic(id: String)
    case spotify(uri: String)
    case web(URL)
}
```

`Sources/DaybreakCore/Alarm.swift`:

```swift
import Foundation

public struct Alarm: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var hour: Int
    public var minute: Int
    /// 비어 있으면 1회성 알람이다.
    public var weekdays: Set<Weekday>
    public var label: String?
    public var source: SoundSourceRef
    /// 0.0 ... 1.0
    public var volume: Double
    public var fadeIn: Bool
    /// `nil`이면 스누즈 없음.
    public var snoozeMinutes: Int?
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        weekdays: Set<Weekday> = [],
        label: String? = nil,
        source: SoundSourceRef = .builtIn(name: "Radar"),
        volume: Double = 0.7,
        fadeIn: Bool = true,
        snoozeMinutes: Int? = 9,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.label = label
        self.source = source
        self.volume = volume
        self.fadeIn = fadeIn
        self.snoozeMinutes = snoozeMinutes
        self.isEnabled = isEnabled
    }
}
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `swift test`

Expected: PASS — 3개 테스트 전부 통과

- [ ] **Step 6: 커밋**

```bash
git add Package.swift Sources/ Tests/
git commit -m "feat: Alarm 모델과 패키지 뼈대"
```

---

## Task 2: 다음 발생 시각 계산

이 프로젝트에서 틀리기 가장 쉬운 로직이다. 알람이 안 울리는 원인 1순위가 여기다.

**Files:**
- Create: `Sources/DaybreakCore/WallClock.swift`
- Create: `Sources/DaybreakCore/NextOccurrence.swift`
- Test: `Tests/DaybreakCoreTests/NextOccurrenceTests.swift`

**Interfaces:**
- Consumes: `Alarm`, `Weekday` (Task 1)
- Produces:
  - `protocol WallClock: Sendable { var now: Date { get } }`
  - `struct SystemClock: WallClock` — `init()`
  - `enum NextOccurrence { static func next(for alarm: Alarm, after date: Date, calendar: Calendar) -> Date? }` — 알람이 꺼져 있으면 `nil`

- [ ] **Step 1: 실패하는 테스트 작성**

`Tests/DaybreakCoreTests/NextOccurrenceTests.swift`:

```swift
import Testing
import Foundation
@testable import DaybreakCore

/// 테스트는 절대 실제 시계나 실행 머신의 시간대에 의존하지 않는다.
private let seoul = TimeZone(identifier: "Asia/Seoul")!

private func makeCalendar(_ tz: TimeZone = seoul) -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    return cal
}

private func date(
    _ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int,
    _ tz: TimeZone = seoul
) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    return cal.date(from: DateComponents(
        year: y, month: mo, day: d, hour: h, minute: mi, second: 0
    ))!
}

@Test("반복 없는 알람: 오늘 시각이 아직 안 지났으면 오늘이다")
func oneShotLaterToday() {
    // 2026-09-02는 수요일
    let alarm = Alarm(hour: 7, minute: 0)
    let now = date(2026, 9, 2, 6, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    #expect(next == date(2026, 9, 2, 7, 0))
}

@Test("반복 없는 알람: 오늘 시각이 지났으면 내일이다")
func oneShotTomorrow() {
    let alarm = Alarm(hour: 7, minute: 0)
    let now = date(2026, 9, 2, 8, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    #expect(next == date(2026, 9, 3, 7, 0))
}

@Test("정확히 알람 시각일 때는 다음 날로 넘어간다")
func exactlyAtAlarmTimeMovesOn() {
    let alarm = Alarm(hour: 7, minute: 0)
    let now = date(2026, 9, 2, 7, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    #expect(next == date(2026, 9, 3, 7, 0))
}

@Test("평일 반복: 금요일 저녁이면 다음은 월요일이다")
func weekdayRepeatSkipsWeekend() {
    let alarm = Alarm(
        hour: 7, minute: 0,
        weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]
    )
    // 2026-09-04는 금요일
    let now = date(2026, 9, 4, 20, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    // 2026-09-07이 월요일
    #expect(next == date(2026, 9, 7, 7, 0))
}

@Test("여러 요일이 걸려 있으면 그중 가장 이른 날을 고른다")
func picksEarliestMatchingWeekday() {
    let alarm = Alarm(hour: 7, minute: 0, weekdays: [.monday, .thursday])
    // 2026-09-02 수요일 저녁 → 목요일이 월요일보다 이르다
    let now = date(2026, 9, 2, 20, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    #expect(next == date(2026, 9, 3, 7, 0))
}

@Test("꺼져 있는 알람은 다음 발생 시각이 없다")
func disabledAlarmHasNoNext() {
    var alarm = Alarm(hour: 7, minute: 0)
    alarm.isEnabled = false
    let now = date(2026, 9, 2, 6, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    #expect(next == nil)
}

@Test("서머타임으로 건너뛴 시각이어도 nil을 내지 않는다")
func survivesDaylightSavingGap() {
    // 뉴욕은 2026-03-08 02:00에 03:00으로 건너뛴다. 02:30은 존재하지 않는다.
    let newYork = TimeZone(identifier: "America/New_York")!
    let alarm = Alarm(hour: 2, minute: 30)
    let now = date(2026, 3, 8, 1, 0, newYork)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar(newYork))

    // 존재하지 않는 시각이므로 그 다음 유효한 시각으로 밀린다.
    // 정확히 언제인지보다 "nil이 아니고 현재보다 미래"라는 점이 중요하다.
    #expect(next != nil)
    #expect(next! > now)
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `swift test`

Expected: FAIL — `cannot find 'NextOccurrence' in scope`

- [ ] **Step 3: 최소 구현 작성**

`Sources/DaybreakCore/WallClock.swift`:

```swift
import Foundation

/// 현재 시각을 주입하기 위한 통로. 테스트가 실제 시계에 의존하지 않게 한다.
public protocol WallClock: Sendable {
    var now: Date { get }
}

public struct SystemClock: WallClock {
    public init() {}
    public var now: Date { Date() }
}
```

`Sources/DaybreakCore/NextOccurrence.swift`:

```swift
import Foundation

/// 알람의 다음 발생 시각을 계산한다. 부수 효과가 없는 순수 함수다.
public enum NextOccurrence {

    /// - Returns: `date` 이후 가장 이른 발생 시각. 알람이 꺼져 있으면 `nil`.
    public static func next(
        for alarm: Alarm,
        after date: Date,
        calendar: Calendar
    ) -> Date? {
        guard alarm.isEnabled else { return nil }

        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute
        components.second = 0

        // 반복 요일이 없으면 1회성 알람이다. 오늘 아니면 내일.
        if alarm.weekdays.isEmpty {
            return calendar.nextDate(
                after: date,
                matching: components,
                matchingPolicy: .nextTime
            )
        }

        // 요일마다 다음 발생 시각을 구해서 가장 이른 것을 고른다.
        // `.nextTime` 정책은 서머타임으로 사라진 시각을 다음 유효 시각으로 민다.
        return alarm.weekdays.compactMap { weekday -> Date? in
            var dayComponents = components
            dayComponents.weekday = weekday.rawValue
            return calendar.nextDate(
                after: date,
                matching: dayComponents,
                matchingPolicy: .nextTime
            )
        }.min()
    }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `swift test`

Expected: PASS — 7개 테스트 전부 통과

- [ ] **Step 5: 커밋**

```bash
git add Sources/DaybreakCore/WallClock.swift Sources/DaybreakCore/NextOccurrence.swift Tests/
git commit -m "feat: 다음 발생 시각 계산"
```

---

## Task 3: 알람 영속화

**Files:**
- Create: `Sources/DaybreakCore/AlarmStore.swift`
- Test: `Tests/DaybreakCoreTests/AlarmStoreTests.swift`

**Interfaces:**
- Consumes: `Alarm` (Task 1)
- Produces:
  - `struct AlarmStore: Sendable` — `init(fileURL: URL)`, `static var defaultFileURL: URL`
  - `func load() -> [Alarm]` — 파일이 없거나 깨졌으면 빈 배열. 절대 throw하지 않는다
  - `func save(_ alarms: [Alarm]) throws`
  - `static var seedAlarms: [Alarm]` — 첫 실행 때 넣을 알람

- [ ] **Step 1: 실패하는 테스트 작성**

`Tests/DaybreakCoreTests/AlarmStoreTests.swift`:

```swift
import Testing
import Foundation
@testable import DaybreakCore

private func makeTempStore() -> (AlarmStore, URL) {
    let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("daybreak-test-\(UUID().uuidString)")
    let file = dir.appendingPathComponent("alarms.json")
    return (AlarmStore(fileURL: file), dir)
}

@Test("저장한 알람을 다시 읽으면 그대로다")
func saveThenLoadRoundTrip() throws {
    let (store, dir) = makeTempStore()
    defer { try? FileManager.default.removeItem(at: dir) }

    let alarms = [
        Alarm(hour: 7, minute: 0, weekdays: [.monday, .friday]),
        Alarm(hour: 9, minute: 30, label: "주말"),
    ]

    try store.save(alarms)

    #expect(store.load() == alarms)
}

@Test("파일이 없으면 빈 배열을 준다")
func loadMissingFileGivesEmpty() {
    let (store, dir) = makeTempStore()
    defer { try? FileManager.default.removeItem(at: dir) }

    #expect(store.load().isEmpty)
}

@Test("JSON이 깨졌으면 빈 배열을 주고 원본을 옆에 남긴다")
func loadCorruptFileGivesEmptyAndKeepsBackup() throws {
    let (store, dir) = makeTempStore()
    defer { try? FileManager.default.removeItem(at: dir) }

    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let file = dir.appendingPathComponent("alarms.json")
    try Data("{ 이건 JSON이 아니다".utf8).write(to: file)

    #expect(store.load().isEmpty)

    // 사용자 데이터를 조용히 버리지 않는다.
    let leftovers = try FileManager.default.contentsOfDirectory(atPath: dir.path)
    #expect(leftovers.contains { $0.hasPrefix("alarms-corrupt-") })
}

@Test("저장은 기존 내용을 완전히 대체한다")
func saveReplacesPreviousContents() throws {
    let (store, dir) = makeTempStore()
    defer { try? FileManager.default.removeItem(at: dir) }

    try store.save([Alarm(hour: 7, minute: 0), Alarm(hour: 8, minute: 0)])
    try store.save([Alarm(hour: 9, minute: 0)])

    let loaded = store.load()
    #expect(loaded.count == 1)
    #expect(loaded.first?.hour == 9)
}

@Test("첫 실행용 알람은 꺼진 채로 하나 들어 있다")
func seedAlarmIsSingleAndDisabled() {
    // 설계 원칙: 첫 실행 시 빈 화면을 보여주지 않는다.
    #expect(AlarmStore.seedAlarms.count == 1)
    #expect(AlarmStore.seedAlarms[0].hour == 7)
    #expect(AlarmStore.seedAlarms[0].minute == 0)
    #expect(AlarmStore.seedAlarms[0].isEnabled == false)
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `swift test`

Expected: FAIL — `cannot find 'AlarmStore' in scope`

- [ ] **Step 3: 최소 구현 작성**

`Sources/DaybreakCore/AlarmStore.swift`:

```swift
import Foundation

/// 알람 목록을 JSON 파일 하나에 저장한다. 데이터베이스는 쓰지 않는다.
public struct AlarmStore: Sendable {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static var defaultFileURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Daybreak", isDirectory: true)
            .appendingPathComponent("alarms.json")
    }

    /// 첫 실행 때 넣을 알람. 빈 화면을 보여주지 않기 위한 것이므로 꺼둔다.
    public static var seedAlarms: [Alarm] {
        [Alarm(hour: 7, minute: 0, isEnabled: false)]
    }

    /// 읽기는 절대 실패하지 않는다. 알람앱이 저장 파일 문제로 못 뜨면 안 된다.
    public func load() -> [Alarm] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        do {
            return try JSONDecoder().decode([Alarm].self, from: data)
        } catch {
            quarantineCorruptFile()
            return []
        }
    }

    public func save(_ alarms: [Alarm]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        // 쓰다가 죽어도 반쪽짜리 파일이 남지 않게 한다.
        try encoder.encode(alarms).write(to: fileURL, options: .atomic)
    }

    /// 깨진 파일을 조용히 덮어쓰지 않고 옆에 치워둔다.
    private func quarantineCorruptFile() {
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("alarms-corrupt-\(stamp).json")
        try? FileManager.default.moveItem(at: fileURL, to: backup)
    }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `swift test`

Expected: PASS — 5개 테스트 전부 통과

- [ ] **Step 5: 커밋**

```bash
git add Sources/DaybreakCore/AlarmStore.swift Tests/
git commit -m "feat: 알람 JSON 영속화"
```

---

## Task 4: 스케줄러

**Files:**
- Create: `Sources/DaybreakCore/AlarmTimer.swift`
- Create: `Sources/DaybreakCore/Scheduler.swift`
- Test: `Tests/DaybreakCoreTests/SchedulerTests.swift`

**Interfaces:**
- Consumes: `Alarm`, `NextOccurrence`, `WallClock` (Task 1, 2)
- Produces:
  - `protocol AlarmTimer: AnyObject { func schedule(at: Date, handler: @escaping @MainActor () -> Void); func cancel() }`
  - `final class SystemAlarmTimer: AlarmTimer` — `init()`
  - `@MainActor final class Scheduler` — `init(clock:calendar:timer:onFire:)`
  - `func update(alarms: [Alarm])` — 알람 목록이 바뀔 때마다 호출. 다음 알람을 다시 계산해 타이머를 건다
  - `var nextFire: (alarm: Alarm, date: Date)?` — 메뉴바 표시에 쓴다

- [ ] **Step 1: 실패하는 테스트 작성**

`Tests/DaybreakCoreTests/SchedulerTests.swift`:

```swift
import Testing
import Foundation
@testable import DaybreakCore

private let seoul = TimeZone(identifier: "Asia/Seoul")!

private func testCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = seoul
    return cal
}

private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = seoul
    return cal.date(from: DateComponents(
        year: y, month: mo, day: d, hour: h, minute: mi, second: 0
    ))!
}

private struct FixedClock: WallClock {
    let now: Date
}

@MainActor
private final class FakeTimer: AlarmTimer {
    var scheduledDate: Date?
    var cancelCount = 0
    private var handler: (@MainActor () -> Void)?

    func schedule(at date: Date, handler: @escaping @MainActor () -> Void) {
        scheduledDate = date
        self.handler = handler
    }

    func cancel() {
        cancelCount += 1
        scheduledDate = nil
        handler = nil
    }

    /// 테스트가 시간이 흐른 척한다.
    func triggerNow() {
        handler?()
    }
}

@MainActor
@Test("가장 이른 알람에 타이머를 건다")
func schedulesEarliestAlarm() {
    let timer = FakeTimer()
    let scheduler = Scheduler(
        clock: FixedClock(now: date(2026, 9, 2, 6, 0)),
        calendar: testCalendar(),
        timer: timer,
        onFire: { _ in }
    )

    scheduler.update(alarms: [
        Alarm(hour: 9, minute: 0),
        Alarm(hour: 7, minute: 0),
    ])

    #expect(timer.scheduledDate == date(2026, 9, 2, 7, 0))
    #expect(scheduler.nextFire?.alarm.hour == 7)
}

@MainActor
@Test("꺼진 알람은 무시한다")
func ignoresDisabledAlarms() {
    let timer = FakeTimer()
    let scheduler = Scheduler(
        clock: FixedClock(now: date(2026, 9, 2, 6, 0)),
        calendar: testCalendar(),
        timer: timer,
        onFire: { _ in }
    )

    scheduler.update(alarms: [
        Alarm(hour: 7, minute: 0, isEnabled: false),
        Alarm(hour: 9, minute: 0),
    ])

    #expect(timer.scheduledDate == date(2026, 9, 2, 9, 0))
}

@MainActor
@Test("켜진 알람이 하나도 없으면 타이머를 끈다")
func cancelsWhenNothingEnabled() {
    let timer = FakeTimer()
    let scheduler = Scheduler(
        clock: FixedClock(now: date(2026, 9, 2, 6, 0)),
        calendar: testCalendar(),
        timer: timer,
        onFire: { _ in }
    )

    scheduler.update(alarms: [Alarm(hour: 7, minute: 0, isEnabled: false)])

    #expect(timer.scheduledDate == nil)
    #expect(scheduler.nextFire == nil)
}

@MainActor
@Test("시각이 되면 그 알람을 넘겨준다")
func firesWithTheCorrectAlarm() {
    let timer = FakeTimer()
    var fired: [Alarm] = []
    let scheduler = Scheduler(
        clock: FixedClock(now: date(2026, 9, 2, 6, 0)),
        calendar: testCalendar(),
        timer: timer,
        onFire: { fired.append($0) }
    )

    let target = Alarm(hour: 7, minute: 0, label: "기상")
    scheduler.update(alarms: [target, Alarm(hour: 9, minute: 0)])
    timer.triggerNow()

    #expect(fired.count == 1)
    #expect(fired.first?.id == target.id)
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `swift test`

Expected: FAIL — `cannot find 'Scheduler' in scope`, `cannot find 'AlarmTimer' in scope`

- [ ] **Step 3: 최소 구현 작성**

`Sources/DaybreakCore/AlarmTimer.swift`:

```swift
import Foundation

/// 타이머를 갈아끼울 수 있게 하는 통로. 테스트는 시간이 흐르길 기다리지 않는다.
@MainActor
public protocol AlarmTimer: AnyObject {
    func schedule(at date: Date, handler: @escaping @MainActor () -> Void)
    func cancel()
}

@MainActor
public final class SystemAlarmTimer: AlarmTimer {
    private var timer: Timer?

    public init() {}

    public func schedule(at date: Date, handler: @escaping @MainActor () -> Void) {
        cancel()
        // 이미 지난 시각이면 즉시 발화한다.
        let interval = max(0, date.timeIntervalSinceNow)
        let timer = Timer(timeInterval: interval, repeats: false) { _ in
            MainActor.assumeIsolated { handler() }
        }
        // .common 모드로 넣어야 메뉴를 열어둔 동안에도 발화한다.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func cancel() {
        timer?.invalidate()
        timer = nil
    }
}
```

`Sources/DaybreakCore/Scheduler.swift`:

```swift
import Foundation

/// 알람 목록에서 다음에 울릴 하나를 골라 타이머를 건다.
@MainActor
public final class Scheduler {
    private let clock: WallClock
    private let calendar: Calendar
    private let timer: AlarmTimer
    private let onFire: (Alarm) -> Void

    public private(set) var nextFire: (alarm: Alarm, date: Date)?

    public init(
        clock: WallClock,
        calendar: Calendar,
        timer: AlarmTimer,
        onFire: @escaping (Alarm) -> Void
    ) {
        self.clock = clock
        self.calendar = calendar
        self.timer = timer
        self.onFire = onFire
    }

    /// 알람이 추가·수정·삭제되거나, 앱이 시작하거나, 절전에서 깨어날 때 호출한다.
    public func update(alarms: [Alarm]) {
        let candidates = alarms.compactMap { alarm -> (alarm: Alarm, date: Date)? in
            guard let date = NextOccurrence.next(
                for: alarm, after: clock.now, calendar: calendar
            ) else { return nil }
            return (alarm, date)
        }

        guard let earliest = candidates.min(by: { $0.date < $1.date }) else {
            nextFire = nil
            timer.cancel()
            return
        }

        nextFire = earliest
        timer.schedule(at: earliest.date) { [weak self] in
            guard let self else { return }
            self.onFire(earliest.alarm)
        }
    }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `swift test`

Expected: PASS — 4개 테스트 전부 통과

- [ ] **Step 5: 커밋**

```bash
git add Sources/DaybreakCore/AlarmTimer.swift Sources/DaybreakCore/Scheduler.swift Tests/
git commit -m "feat: 알람 스케줄러"
```

---

## Task 5: 백업 톤 생성

macOS 시스템 사운드(`/System/Library/Sounds/`)는 전부 1초 미만의 짧은 효과음이라 알람으로 못 쓴다. 그래서 **소리를 파일이 아니라 코드로 만든다.** 파일이 없으니 파일이 없어서 못 울릴 일도 없다 — 설계 문서 §7.4의 백업음이 이것이다.

**Files:**
- Create: `Sources/DaybreakCore/TonePattern.swift`
- Test: `Tests/DaybreakCoreTests/TonePatternTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `struct TonePattern: Sendable` — `init(frequency: Double, beepDuration: Double, gapDuration: Double, beepCount: Int)`
  - `static let radar: TonePattern` — 백업음
  - `func samples(sampleRate: Double) -> [Float]` — 한 주기 분량의 PCM 샘플. 재생 시 이것을 무한 반복한다
  - `var cycleDuration: Double`

- [ ] **Step 1: 실패하는 테스트 작성**

`Tests/DaybreakCoreTests/TonePatternTests.swift`:

```swift
import Testing
import Foundation
@testable import DaybreakCore

@Test("한 주기 길이는 삑 소리와 침묵의 합이다")
func cycleDurationIsSumOfParts() {
    let pattern = TonePattern(
        frequency: 880, beepDuration: 0.2, gapDuration: 0.3, beepCount: 2
    )

    // (0.2 + 0.3) * 2 = 1.0
    #expect(abs(pattern.cycleDuration - 1.0) < 0.0001)
}

@Test("샘플 개수는 주기 길이와 샘플레이트를 곱한 값이다")
func sampleCountMatchesDuration() {
    let pattern = TonePattern(
        frequency: 880, beepDuration: 0.2, gapDuration: 0.3, beepCount: 2
    )

    let samples = pattern.samples(sampleRate: 44_100)

    #expect(samples.count == 44_100)
}

@Test("삑 구간에는 소리가 있고 침묵 구간에는 없다")
func beepsAreLoudAndGapsAreSilent() {
    let pattern = TonePattern(
        frequency: 880, beepDuration: 0.2, gapDuration: 0.3, beepCount: 1
    )
    let sampleRate = 44_100.0
    let samples = pattern.samples(sampleRate: sampleRate)

    // 사인파는 주기적으로 0을 지난다. 한 샘플만 보면 소리가 나는 중에도
    // 0이 나올 수 있으므로, 구간 전체의 최대 진폭으로 판단한다.
    func peak(from start: Double, to end: Double) -> Float {
        let range = Int(start * sampleRate)..<Int(end * sampleRate)
        return samples[range].map(abs).max() ?? 0
    }

    #expect(peak(from: 0.05, to: 0.15) > 0.5)   // 삑 구간 한복판
    #expect(peak(from: 0.25, to: 0.45) == 0)    // 침묵 구간
}

@Test("모든 샘플이 -1...1 범위 안에 있다")
func samplesStayInRange() {
    let samples = TonePattern.radar.samples(sampleRate: 44_100)

    #expect(!samples.isEmpty)
    #expect(samples.allSatisfy { $0 >= -1.0 && $0 <= 1.0 })
}

@Test("백업음은 잠을 깨울 만큼 반복적이다")
func radarPatternIsRepetitive() {
    // 한 주기가 너무 길면 알람으로 안 들린다.
    #expect(TonePattern.radar.cycleDuration <= 2.0)
    #expect(TonePattern.radar.beepCount >= 2)
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `swift test`

Expected: FAIL — `cannot find 'TonePattern' in scope`

- [ ] **Step 3: 최소 구현 작성**

`Sources/DaybreakCore/TonePattern.swift`:

```swift
import Foundation

/// 알람음의 파형을 코드로 만든다.
///
/// 오디오 파일을 번들하지 않는 이유는 신뢰성 때문이다. 파일은 없어지거나
/// 깨질 수 있지만 계산된 파형은 그럴 수 없다. 설계 문서 §7.4의 백업음이 이것이다.
public struct TonePattern: Sendable {
    /// 헤르츠.
    public let frequency: Double
    /// 삑 소리 하나의 길이 (초).
    public let beepDuration: Double
    /// 삑 소리 사이 침묵의 길이 (초).
    public let gapDuration: Double
    /// 한 주기에 들어가는 삑 소리 개수.
    public let beepCount: Int

    public init(
        frequency: Double,
        beepDuration: Double,
        gapDuration: Double,
        beepCount: Int
    ) {
        self.frequency = frequency
        self.beepDuration = beepDuration
        self.gapDuration = gapDuration
        self.beepCount = beepCount
    }

    /// 기본 백업음. 짧게 두 번 울리고 쉬는 것을 반복한다.
    public static let radar = TonePattern(
        frequency: 880,
        beepDuration: 0.15,
        gapDuration: 0.25,
        beepCount: 3
    )

    public var cycleDuration: Double {
        (beepDuration + gapDuration) * Double(beepCount)
    }

    /// 한 주기 분량의 모노 PCM 샘플. 재생 쪽에서 무한 반복한다.
    public func samples(sampleRate: Double) -> [Float] {
        let total = Int((cycleDuration * sampleRate).rounded())
        let beepSamples = Int((beepDuration * sampleRate).rounded())
        let unitSamples = Int(((beepDuration + gapDuration) * sampleRate).rounded())

        var result = [Float](repeating: 0, count: total)

        for index in 0..<total {
            let positionInUnit = index % unitSamples
            guard positionInUnit < beepSamples else { continue }  // 침묵 구간

            let phase = 2.0 * Double.pi * frequency * Double(index) / sampleRate
            // 삑 소리의 시작과 끝을 부드럽게 깎아 딱딱거리는 잡음을 없앤다.
            let envelope = Self.envelope(
                position: positionInUnit, length: beepSamples, sampleRate: sampleRate
            )
            result[index] = Float(sin(phase) * envelope * 0.8)
        }

        return result
    }

    /// 앞뒤 5밀리초를 선형으로 올리고 내린다.
    private static func envelope(
        position: Int, length: Int, sampleRate: Double
    ) -> Double {
        let rampSamples = max(1, Int(0.005 * sampleRate))
        guard length > rampSamples * 2 else { return 1.0 }

        if position < rampSamples {
            return Double(position) / Double(rampSamples)
        }
        if position > length - rampSamples {
            return Double(length - position) / Double(rampSamples)
        }
        return 1.0
    }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `swift test`

Expected: PASS — 5개 테스트 전부 통과

- [ ] **Step 5: 커밋**

```bash
git add Sources/DaybreakCore/TonePattern.swift Tests/
git commit -m "feat: 코드로 만드는 백업 알람음"
```

---

## Task 6: 앱 껍데기와 알람 목록 창

여기부터는 UI라 유닛 테스트를 쓰지 않는다. 대신 **매 태스크마다 눈으로 확인하는 절차**를 둔다.

**Files:**
- Create: `Resources/Info.plist`
- Create: `Scripts/bundle.sh`
- Create: `Sources/Daybreak/TonePlayer.swift`
- Create: `Sources/Daybreak/AlarmListModel.swift`
- Create: `Sources/Daybreak/AlarmListView.swift`
- Modify: `Sources/Daybreak/DaybreakApp.swift` (Task 1에서 만든 자리채움을 완전히 대체)

**Interfaces:**
- Consumes: `Alarm`, `AlarmStore`, `Scheduler`, `SystemAlarmTimer`, `SystemClock`, `TonePattern` (Task 1–5)
- Produces:
  - `@MainActor @Observable final class AlarmListModel` — `init(store: AlarmStore)`, `var alarms: [Alarm]`, `var editing: Alarm?`, `var firing: Alarm?`, `func toggle(_ alarm: Alarm)`, `func addAlarm()`, `func save(_ alarm: Alarm)`, `func delete(_ alarm: Alarm)`, `var nextFireDate: Date?`
  - `@MainActor final class TonePlayer` — `init()`, `func start(pattern: TonePattern, volume: Double, fadeIn: Bool)`, `func stop()`
  - `struct AlarmListView: View` — `init(model: AlarmListModel)`

- [ ] **Step 1: 번들 메타데이터와 조립 스크립트 작성**

`Resources/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Daybreak</string>
    <key>CFBundleDisplayName</key>
    <string>Daybreak</string>
    <key>CFBundleIdentifier</key>
    <string>com.daybreak.app</string>
    <key>CFBundleExecutable</key>
    <string>Daybreak</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

`Scripts/bundle.sh`:

```bash
#!/bin/bash
# Daybreak.app 번들을 조립한다. SwiftUI 앱은 번들 안에서 실행해야
# Dock 아이콘과 창 활성화가 정상 동작한다.
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
swift build -c "$CONFIG" --product Daybreak

BIN="$(swift build -c "$CONFIG" --product Daybreak --show-bin-path)/Daybreak"
APP="build/Daybreak.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Daybreak"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# 로컬 실행용 임시 서명. 배포용 Developer ID 서명은 나중 단계에서 다룬다.
codesign --force --sign - "$APP"

echo "빌드 완료: $APP"
```

```bash
chmod +x Scripts/bundle.sh
```

- [ ] **Step 2: 톤 재생기 작성**

`Sources/Daybreak/TonePlayer.swift`:

```swift
import AVFAudio
import Foundation
import DaybreakCore

/// `TonePattern`이 만든 파형을 실제 소리로 낸다. 끌 때까지 무한 반복한다.
@MainActor
final class TonePlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var fadeTimer: Timer?

    init() {
        engine.attach(player)
    }

    func start(pattern: TonePattern, volume: Double, fadeIn: Bool) {
        stop()

        let sampleRate = 44_100.0
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate, channels: 1
        ) else { return }

        let samples = pattern.samples(sampleRate: sampleRate)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)
        ) else { return }

        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channel = buffer.floatChannelData?[0] {
            for (index, sample) in samples.enumerated() {
                channel[index] = sample
            }
        }

        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = fadeIn ? 0.0 : Float(volume)

        do {
            try engine.start()
        } catch {
            // 엔진이 안 뜨면 알람이 소리를 못 낸다. 3단계 AudioGuard가 다룰 영역이다.
            return
        }

        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()

        if fadeIn {
            startFade(to: Float(volume))
        }
    }

    func stop() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        player.stop()
        engine.stop()
    }

    /// 30초에 걸쳐 목표 볼륨까지 올린다.
    private func startFade(to target: Float) {
        let duration = 30.0
        let tick = 0.5
        let step = target / Float(duration / tick)

        fadeTimer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self else { timer.invalidate(); return }
                let current = self.engine.mainMixerNode.outputVolume
                let next = min(target, current + step)
                self.engine.mainMixerNode.outputVolume = next
                if next >= target { timer.invalidate() }
            }
        }
    }
}
```

- [ ] **Step 3: 목록 모델 작성**

`Sources/Daybreak/AlarmListModel.swift`:

```swift
import Foundation
import Observation
import DaybreakCore

@MainActor
@Observable
final class AlarmListModel {
    private(set) var alarms: [Alarm] = []

    /// 편집 시트에 띄울 알람. `nil`이면 시트가 닫혀 있다.
    var editing: Alarm?
    /// 지금 울리고 있는 알람. `nil`이면 오버레이가 안 떠 있다.
    var firing: Alarm?

    private let store: AlarmStore
    private var scheduler: Scheduler?
    private let player = TonePlayer()

    init(store: AlarmStore = AlarmStore(fileURL: AlarmStore.defaultFileURL)) {
        self.store = store

        let loaded = store.load()
        // 첫 실행 시 빈 화면을 보여주지 않는다 (설계 원칙).
        alarms = loaded.isEmpty ? AlarmStore.seedAlarms : loaded

        scheduler = Scheduler(
            clock: SystemClock(),
            calendar: Calendar.current,
            timer: SystemAlarmTimer(),
            onFire: { [weak self] alarm in
                self?.fire(alarm)
            }
        )
        reschedule()
    }

    var nextFireDate: Date? {
        scheduler?.nextFire?.date
    }

    func toggle(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
        persist()
    }

    func addAlarm() {
        editing = Alarm(hour: 7, minute: 0)
    }

    func save(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }
        alarms.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        persist()
    }

    func delete(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        persist()
    }

    /// 스페이스바로 알람을 완전히 껐을 때.
    func dismissFiring() {
        player.stop()
        if let alarm = firing, alarm.weekdays.isEmpty {
            // 1회성 알람은 울리고 나면 꺼둔다.
            if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
                alarms[index].isEnabled = false
            }
        }
        firing = nil
        persist()
    }

    /// 스누즈. 마우스 클릭으로만 도달한다.
    func snoozeFiring() {
        guard let alarm = firing, let minutes = alarm.snoozeMinutes else { return }
        player.stop()
        firing = nil

        let snoozeAt = Date().addingTimeInterval(Double(minutes) * 60)
        Timer.scheduledTimer(withTimeInterval: snoozeAt.timeIntervalSinceNow, repeats: false) { _ in
            MainActor.assumeIsolated { [weak self] in
                self?.fire(alarm)
            }
        }
    }

    private func fire(_ alarm: Alarm) {
        firing = alarm
        // 1단계에서 재생되는 소스는 .builtIn 하나뿐이다.
        // 2단계에서 PlaybackChain이 이 자리를 대체한다.
        player.start(pattern: .radar, volume: alarm.volume, fadeIn: alarm.fadeIn)
    }

    private func persist() {
        try? store.save(alarms)
        reschedule()
    }

    private func reschedule() {
        scheduler?.update(alarms: alarms)
    }
}
```

- [ ] **Step 4: 목록 화면 작성**

`Sources/Daybreak/AlarmListView.swift`:

```swift
import SwiftUI
import DaybreakCore

struct AlarmListView: View {
    @Bindable var model: AlarmListModel

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(model.alarms) { alarm in
                    AlarmRow(alarm: alarm) {
                        model.toggle(alarm)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { model.editing = alarm }
                    .contextMenu {
                        Button("삭제", role: .destructive) { model.delete(alarm) }
                    }
                }
            }
            .listStyle(.inset)

            Divider()

            Button {
                model.addAlarm()
            } label: {
                Label("알람 추가", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .padding(8)
        }
        .frame(minWidth: 320, minHeight: 360)
        .navigationTitle("알람")
    }
}

private struct AlarmRow: View {
    let alarm: Alarm
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(timeText)
                    .font(.system(size: 30, weight: .light))
                    .monospacedDigit()
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: { _ in onToggle() }))
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .opacity(alarm.isEnabled ? 1.0 : 0.45)
        .padding(.vertical, 4)
    }

    private var timeText: String {
        String(format: "%d:%02d", alarm.hour == 0 ? 12 : (alarm.hour > 12 ? alarm.hour - 12 : alarm.hour), alarm.minute)
            + (alarm.hour < 12 ? " AM" : " PM")
    }

    private var subtitleText: String {
        let days = alarm.weekdays.isEmpty
            ? "한 번만"
            : Weekday.displayOrder
                .filter { alarm.weekdays.contains($0) }
                .map(\.shortName)
                .joined(separator: "·")
        if let label = alarm.label, !label.isEmpty {
            return "\(days) · \(label)"
        }
        return days
    }
}
```

- [ ] **Step 5: 앱 진입점 교체**

`Sources/Daybreak/DaybreakApp.swift` 내용을 전부 아래로 바꾼다.

```swift
import SwiftUI
import DaybreakCore

@main
struct DaybreakApp: App {
    @State private var model = AlarmListModel()

    var body: some Scene {
        Window("알람", id: "alarms") {
            AlarmListView(model: model)
        }
        .windowResizability(.contentSize)
    }
}
```

- [ ] **Step 6: 빌드하고 눈으로 확인**

```bash
./Scripts/bundle.sh
open build/Daybreak.app
```

Expected:
- 창이 뜨고 제목이 "알람"이다
- 7:00 AM 알람이 **꺼진 상태로 하나** 보인다 (빈 화면이 아니다)
- 토글을 켜고 앱을 껐다 켜면 켜진 상태가 유지된다
- `cat ~/Library/Application\ Support/Daybreak/alarms.json` 에 그 알람이 보인다

- [ ] **Step 7: 커밋**

```bash
git add Resources/ Scripts/ Sources/Daybreak/
git commit -m "feat: 알람 목록 창과 앱 번들"
```

---

## Task 7: 알람 편집 시트

**Files:**
- Create: `Sources/Daybreak/AlarmEditView.swift`
- Modify: `Sources/Daybreak/AlarmListView.swift` (시트 표시 추가)

**Interfaces:**
- Consumes: `Alarm`, `Weekday` (Task 1), `AlarmListModel` (Task 6)
- Produces: `struct AlarmEditView: View` — `init(alarm: Alarm, onSave: @escaping (Alarm) -> Void, onCancel: @escaping () -> Void)`

- [ ] **Step 1: 편집 시트 작성**

시각은 타이핑이 기본이고, 알람별 설정은 볼륨·페이드인·스누즈 셋뿐이다 (설계 원칙 4). 사운드 선택은 2단계에서 옴니박스가 들어올 자리이므로 지금은 백업음 고정이라고 표시만 한다.

`Sources/Daybreak/AlarmEditView.swift`:

```swift
import SwiftUI
import DaybreakCore

struct AlarmEditView: View {
    @State private var alarm: Alarm
    private let onSave: (Alarm) -> Void
    private let onCancel: () -> Void

    init(
        alarm: Alarm,
        onSave: @escaping (Alarm) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _alarm = State(initialValue: alarm)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 18) {
            timeField
            weekdayPicker
            soundSection
            volumeSection

            HStack {
                Button("취소", role: .cancel) { onCancel() }
                Spacer()
                Button("저장") { onSave(alarm) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 340)
    }

    // 드럼 휠 대신 키보드로 친다. Mac에는 키보드가 있다.
    private var timeField: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                TextField("", value: $alarm.hour, format: .number)
                    .frame(width: 62)
                Text(":")
                TextField("", value: $alarm.minute, format: .number)
                    .frame(width: 62)
            }
            .textFieldStyle(.plain)
            .font(.system(size: 42, weight: .thin))
            .monospacedDigit()
            .multilineTextAlignment(.center)

            Text("숫자를 입력하세요")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .onChange(of: alarm.hour) { _, new in
            alarm.hour = min(23, max(0, new))
        }
        .onChange(of: alarm.minute) { _, new in
            alarm.minute = min(59, max(0, new))
        }
    }

    private var weekdayPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("반복").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                ForEach(Weekday.displayOrder, id: \.self) { day in
                    Button(day.shortName) {
                        if alarm.weekdays.contains(day) {
                            alarm.weekdays.remove(day)
                        } else {
                            alarm.weekdays.insert(day)
                        }
                    }
                    .buttonStyle(.borderless)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(alarm.weekdays.contains(day) ? Color.accentColor : Color.secondary.opacity(0.15))
                    .foregroundStyle(alarm.weekdays.contains(day) ? Color.white : Color.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    // 2단계에서 옴니박스가 이 자리를 대체한다.
    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("무엇으로 깨울까요").font(.caption).foregroundStyle(.secondary)
            HStack {
                Image(systemName: "bell.fill")
                Text("Radar")
                Spacer()
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("볼륨").font(.caption).foregroundStyle(.secondary)
            Slider(value: $alarm.volume, in: 0...1)
            Toggle("서서히 커지기", isOn: $alarm.fadeIn)
            Toggle("스누즈 9분", isOn: Binding(
                get: { alarm.snoozeMinutes != nil },
                set: { alarm.snoozeMinutes = $0 ? 9 : nil }
            ))
        }
    }
}
```

- [ ] **Step 2: 목록에서 시트를 띄우도록 연결**

`Sources/Daybreak/AlarmListView.swift`의 `.navigationTitle("알람")` 바로 아래에 다음을 추가한다.

```swift
        .sheet(item: $model.editing) { alarm in
            AlarmEditView(
                alarm: alarm,
                onSave: { updated in
                    model.save(updated)
                    model.editing = nil
                },
                onCancel: { model.editing = nil }
            )
        }
```

- [ ] **Step 3: 빌드하고 눈으로 확인**

```bash
./Scripts/bundle.sh
open build/Daybreak.app
```

Expected:
- `＋ 알람 추가`를 누르면 시트가 뜬다
- 시각 칸에 숫자를 **타이핑**할 수 있다
- 25를 입력하면 23으로 잘린다
- 요일 칩을 누르면 파랗게 켜지고 다시 누르면 꺼진다
- 저장하면 목록에 시각순으로 들어간다
- 앱을 껐다 켜도 남아 있다

- [ ] **Step 4: 커밋**

```bash
git add Sources/Daybreak/
git commit -m "feat: 알람 편집 시트"
```

---

## Task 8: 알람 오버레이와 스페이스바 해제

이 계획의 핵심 태스크다. 여기가 동작하면 앱이 알람앱이 된다.

**Files:**
- Create: `Sources/Daybreak/AlarmOverlayWindow.swift`
- Create: `Sources/Daybreak/AlarmOverlayView.swift`
- Modify: `Sources/Daybreak/AlarmListModel.swift` (오버레이 창 띄우기/내리기)

**Interfaces:**
- Consumes: `Alarm` (Task 1), `AlarmListModel` (Task 6)
- Produces:
  - `final class AlarmOverlayWindow: NSWindow` — `init(screen: NSScreen, onDismiss: @escaping () -> Void)`
  - `@MainActor final class AlarmOverlayController` — `init()`, `func show(alarm: Alarm, onDismiss: @escaping () -> Void, onSnooze: @escaping () -> Void)`, `func hide()`
  - `struct AlarmOverlayView: View` — `init(alarm: Alarm, onSnooze: @escaping () -> Void)`

- [ ] **Step 1: 오버레이 창 작성**

`Sources/Daybreak/AlarmOverlayWindow.swift`:

```swift
import AppKit
import SwiftUI
import DaybreakCore

/// 전체화면을 점유하는 알람 창.
///
/// 키 처리 규칙: **스페이스바만 받고 나머지는 전부 삼킨다.** `super.keyDown`을
/// 호출하지 않으므로 다른 키를 눌러도 아무 일이 없고 비프음도 안 난다.
/// 스누즈에 키보드로 도달할 수 없게 만드는 것이 이 규칙의 목적이다.
final class AlarmOverlayWindow: NSWindow {
    private let onDismiss: () -> Void

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(screen: NSScreen, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = true
        backgroundColor = .black
        hasShadow = false
    }

    override func keyDown(with event: NSEvent) {
        // 49 = 스페이스바
        if event.keyCode == 49 {
            onDismiss()
        }
        // 그 외 키는 의도적으로 무시한다. super를 부르지 않는다.
    }
}

/// 연결된 모든 화면에 오버레이를 띄운다.
@MainActor
final class AlarmOverlayController {
    private var windows: [AlarmOverlayWindow] = []

    func show(
        alarm: Alarm,
        onDismiss: @escaping () -> Void,
        onSnooze: @escaping () -> Void
    ) {
        hide()

        for screen in NSScreen.screens {
            let window = AlarmOverlayWindow(screen: screen, onDismiss: onDismiss)
            window.contentView = NSHostingView(
                rootView: AlarmOverlayView(alarm: alarm, onSnooze: onSnooze)
            )
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
        // 첫 번째 창이 키 창이어야 스페이스바가 들어온다.
        windows.first?.makeKey()
    }

    func hide() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }
}
```

- [ ] **Step 2: 오버레이 화면 작성**

`Sources/Daybreak/AlarmOverlayView.swift`:

```swift
import SwiftUI
import DaybreakCore

struct AlarmOverlayView: View {
    let alarm: Alarm
    let onSnooze: () -> Void

    @State private var now = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.11, green: 0.23, blue: 0.36), .black],
                center: .init(x: 0.5, y: 0.25),
                startRadius: 0,
                endRadius: 900
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(now, format: .dateTime.hour().minute())
                    .font(.system(size: 108, weight: .thin))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(alarm.label ?? "일어날 시간")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, 10)

                Text("🔔 Radar")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 6)

                Text("space")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.14))
                            .strokeBorder(.white.opacity(0.3))
                    )
                    .padding(.top, 46)

                Text("스페이스바를 눌러 끄기")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 9)

                if alarm.snoozeMinutes != nil {
                    // 마우스로만 누를 수 있다. 키보드 포커스를 주지 않는다.
                    Button("스누즈 \(alarm.snoozeMinutes!)분") {
                        onSnooze()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 6)
                    .overlay(
                        Capsule().stroke(.white.opacity(0.2))
                    )
                    .focusable(false)
                    .padding(.top, 34)
                }
            }
        }
        .onReceive(tick) { now = $0 }
    }
}
```

- [ ] **Step 3: 모델에 오버레이 연결**

`Sources/Daybreak/AlarmListModel.swift`를 세 군데 고친다.

프로퍼티 선언부에 컨트롤러를 추가한다. `private let player = TonePlayer()` 아래에:

```swift
    private let overlay = AlarmOverlayController()
```

`fire(_:)` 전체를 아래로 바꾼다:

```swift
    private func fire(_ alarm: Alarm) {
        firing = alarm
        // 1단계에서 재생되는 소스는 .builtIn 하나뿐이다.
        // 2단계에서 PlaybackChain이 이 자리를 대체한다.
        player.start(pattern: .radar, volume: alarm.volume, fadeIn: alarm.fadeIn)
        overlay.show(
            alarm: alarm,
            onDismiss: { [weak self] in self?.dismissFiring() },
            onSnooze: { [weak self] in self?.snoozeFiring() }
        )
    }
```

`dismissFiring()`과 `snoozeFiring()` 각각의 `player.stop()` 바로 다음 줄에 추가한다:

```swift
        overlay.hide()
```

- [ ] **Step 4: 빌드하고 눈으로 확인**

```bash
./Scripts/bundle.sh
open build/Daybreak.app
```

지금 시각 기준 2분 뒤로 알람을 하나 만들고 켠 다음 기다린다.

Expected:
- 시각이 되면 화면 전체가 검게 덮이고 큰 시계가 뜬다
- 소리가 난다 (삑 삑 삑 반복)
- **스페이스바를 누르면 소리가 멈추고 오버레이가 사라진다**
- ESC, 리턴, 아무 글자 키를 눌러도 아무 일이 없고 비프음도 안 난다
- 스누즈 버튼은 마우스로 누르면 동작하고, Tab 키로는 포커스가 안 간다
- 화면이 두 개면 양쪽 다 덮인다

- [ ] **Step 5: 커밋**

```bash
git add Sources/Daybreak/
git commit -m "feat: 알람 오버레이와 스페이스바 해제"
```

---

## Task 9: 메뉴바에 다음 알람 표시

**Files:**
- Modify: `Sources/Daybreak/DaybreakApp.swift`

**Interfaces:**
- Consumes: `AlarmListModel.nextFireDate` (Task 6)
- Produces: 없음 (1단계의 마지막 태스크)

- [ ] **Step 1: 메뉴바 씬 추가**

`Sources/Daybreak/DaybreakApp.swift` 내용을 전부 아래로 바꾼다.

```swift
import SwiftUI
import DaybreakCore

@main
struct DaybreakApp: App {
    @State private var model = AlarmListModel()

    var body: some Scene {
        Window("알람", id: "alarms") {
            AlarmListView(model: model)
        }
        .windowResizability(.contentSize)

        MenuBarExtra(menuBarTitle) {
            if let next = model.nextFireDate {
                Text("다음 알람 \(next.formatted(date: .omitted, time: .shortened))")
            } else {
                Text("켜진 알람 없음")
            }
            Divider()
            Button("종료") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }

    /// 메뉴바에는 다음 알람 시각만 조용히 띄운다.
    private var menuBarTitle: String {
        guard let next = model.nextFireDate else { return "⏰" }
        return "⏰ " + next.formatted(date: .omitted, time: .shortened)
    }
}
```

- [ ] **Step 2: 빌드하고 눈으로 확인**

```bash
./Scripts/bundle.sh
open build/Daybreak.app
```

Expected:
- 메뉴바에 `⏰ 7:00 AM` 같은 표시가 뜬다
- 알람을 전부 끄면 `⏰`만 남는다
- 알람을 켜거나 시각을 바꾸면 메뉴바 표시가 따라 바뀐다

- [ ] **Step 3: 전체 테스트 재실행**

Run: `swift test`

Expected: PASS — Task 1~5의 테스트 24개가 전부 통과한다

- [ ] **Step 4: 커밋**

```bash
git add Sources/Daybreak/
git commit -m "feat: 메뉴바 다음 알람 표시"
```

---

## 1단계 완료 조건

전부 만족해야 2단계로 넘어간다.

- [ ] `swift test`가 통과한다
- [ ] `./Scripts/bundle.sh`로 `build/Daybreak.app`이 만들어진다
- [ ] 알람을 만들고 껐다 켜도 남아 있다
- [ ] 정해둔 시각에 실제로 소리가 나고 화면이 덮인다
- [ ] 스페이스바로 꺼지고, 다른 키로는 안 꺼진다
- [ ] 스누즈가 마우스로만 눌린다
- [ ] Task 0 스파이크 결과 문서가 있다
- [ ] **하루 이상 실제로 이걸로 일어나봤다** — 알람앱은 써보지 않으면 문제를 못 찾는다

## 다음 계획으로 넘길 것

- **2단계 (소스):** `SoundSource` 프로토콜, 6종 구현, 옴니박스, `PlaybackChain`. `AlarmListModel.fire(_:)`의 `player.start`가 `PlaybackChain`으로 교체되는 지점이다
- **3단계 (신뢰성):** `AudioGuard`, `Preflight`, `PowerDaybreak`(Task 0 결과에 따라 방식 결정), 나이트스탠드 화면
- **배포:** Developer ID 서명과 공증. 지금은 임시 서명만 한다
