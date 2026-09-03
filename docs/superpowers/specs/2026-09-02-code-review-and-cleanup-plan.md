# 코드 분석과 개선 기획

작성일: 2026-09-02
대상: `d4b8dd2` 시점의 전체 코드베이스
목적: 빠르게 쌓아올린 구현에서 구조적으로 갚아야 할 빚을 찾고, 갚는 순서를 정한다

---

## 0. 먼저, 잘 되어 있는 것

깎아내리기 전에 실제로 확인한 사실부터 적는다.

- **빌드가 경고 없이 통과한다.** Swift 6 엄격 동시성에서 깨끗하다
- **테스트 36개가 전부 통과한다.** 계획서의 24개에서 늘었다
- **핵심 순수 로직이 제자리에 있다.** `NextOccurrence`, `AlarmStore`, `Scheduler`, `TonePattern`, `OmniboxParser`, `PlaybackChain`이 전부 `MatutaCore`에 있고 테스트가 붙어 있다
- **0단계 스파이크 결과가 문서로 남아 있다** (`docs/superpowers/spikes/2026-09-02-power-wake.md`)
- 설계 문서의 3단계까지 기능이 실제로 동작하는 수준으로 들어왔다

기반은 멀쩡하다. 아래 문제들은 그 위에 얹힌 것이지 기반이 썩은 게 아니다.

## 1. 규모로 본 진단

| 레이어 | 줄 수 | 테스트 |
|---|---|---|
| `MatutaCore` (순수 로직) | 741 | 36개 |
| `Matuta` (앱) | 3,345 | 0개 |
| 테스트 | 593 | — |

**앱 레이어가 코어의 4.5배다.** 설계 문서의 전제는 정반대였다 — "순수 로직을 `MatutaCore`에 몰아넣고 `swift test`로 전부 검증한다. 앱은 그 위에 얹는 얇은 껍데기다."

지금은 얇은 껍데기가 아니라 **몸통이 껍데기 쪽에 가 있다.** 그리고 그 3,345줄에는 테스트가 하나도 없다. 이게 아래 문제 대부분의 뿌리다.

가장 큰 파일:

| 파일 | 줄 수 |
|---|---|
| `AlarmEditView.swift` | 871 |
| `AlarmListView.swift` | 496 |
| `AudioGuard.swift` | 234 |
| `TonePattern.swift` | 227 |
| `MatutaApp.swift` | 222 |

---

## 2. 발견 — 심각도 순

### A. 결정했던 UX가 반대로 구현됐다 · 심각

기획 단계에서 사운드 선택 방식을 세 안 놓고 **B(옴니박스)로 명시적으로 결정**했다. 근거는 "사용자는 소스가 6종이라는 사실을 끝까지 몰라도 되게 만든다"였고, 이건 설계 문서 §4 원칙 3에 그대로 적혀 있다.

현재 구현은 **A안(소스별 탭)이다.** `AlarmEditView.swift:6`의 `SourceTab` enum이 6종을 정의하고, `soundDeckSection`이 그걸 한 줄 바에 전부 펼친다.

게다가 **아이콘만 있고 글자 라벨이 없다.** A안의 원래 단점("사용자가 내 노래가 어느 탭인지 먼저 고민해야 한다")이 더 나빠졌다 — 이제는 아이콘 6개의 뜻을 먼저 알아내야 한다. `.help(tab.rawValue)`로 툴팁은 달려 있지만, 툴팁은 마우스를 올려야 보인다.

`OmniboxParser`는 살아 있지만 **탭 안의 텍스트 필드 파서로 격하**됐다 (`AlarmEditView.swift:827`, `853`, `868`). 코어에 테스트까지 갖춘 모듈이 원래 역할의 일부만 하고 있다.

이건 버그가 아니라 **방향이 뒤집힌 것**이라 제일 위에 둔다.

### B. 알람을 껐는데 백업음이 계속 울릴 수 있다 · 심각

`PlaybackChain.start()`는 `async`이고 내부에 `await` 지점이 둘 있다. `AlarmListModel.fire()`는 이걸 `Task { }`로 던져놓고 기다리지 않는다 (`AlarmListModel.swift:159`).

문제가 되는 순서:

```
1. fire() → Task 예약, overlay 표시
2. 사용자가 스페이스바로 해제 → dismissFiring() → playbackChain.stop()
   stop()이 primarySource/backupSource를 nil로 만든다
3. 그 다음에야 Task가 돌면서 start() 실행 → play() 호출
   → 해제했는데 소리가 시작된다
```

더 나쁜 경우는 `start()` 중간에 `stop()`이 끼어드는 것이다.

```
line 35: await primary.play(...)     ← Spotify 앱 실행. 느리다
         ← 여기서 stop()이 실행됨. backupSource = nil
line 39: await backup.play(...)      ← 지역 변수 backup으로 재생 시작
         → backupSource가 nil이라 이후 어떤 stop()도 이 소리를 못 끈다
```

**끌 수 없는 알람음이 남는다.** 그리고 이 창은 이론적인 게 아니다 — `needsBackupTone`이 참인 소스(Spotify, 웹)에서 `primary.play()`는 외부 앱이나 브라우저를 띄우는 동작이라 수백 밀리초에서 수 초가 걸린다. 사용자가 그 사이에 스페이스바를 누를 가능성은 충분히 높다.

`PlaybackChain`에 세대 카운터나 취소 토큰이 없는 게 원인이다.

### C. 스누즈가 절전과 앱 재시작을 못 버틴다 · 심각

이 앱의 정체성이 "절대 안 울리는 일이 없는 알람"인데, 스누즈 경로가 그 약속을 지키지 못한다.

**절전:** `snoozeFiring()` (`AlarmListModel.swift:115`)은 `snoozeUntil`을 세우고 `Timer`를 걸지만 `reschedule()`을 호출하지 않는다. 그리고 `reschedule()` 자체도 `scheduler?.nextFire?.date`만 보고 `snoozeUntil`을 무시한다 (`:186`). 즉 **스누즈 중에 Mac이 절전에 들어가면 깨우기 예약이 없다.** 9분 뒤에 안 울린다.

`nextFireDate`는 스누즈를 반영하는데(`:47`) `reschedule()`은 안 한다 — 같은 개념을 두 군데서 다르게 계산하고 있다.

**재시작:** `snoozingAlarmID`, `snoozeUntil`, `snoozeTimer`가 전부 메모리에만 있다. 앱이 죽거나 사용자가 종료하면 스누즈가 조용히 사라진다.

### D. 신뢰성 모듈이 테스트할 수 없는 곳에 있다 · 높음

`AudioGuard`(234줄), `PreflightEngine`(112줄), `SystemPowerMatuta`(99줄)가 전부 **앱 타깃**에 있다. 앱 타깃에는 테스트 타깃이 없으므로 이 세 개는 검증이 불가능하다.

설계 문서 §6.1은 이렇게 적고 있다: "`AudioGuard`와 `Preflight`는 같은 상태를 본다. 차이는 시점뿐이다 — `Preflight`는 자기 전에 읽어서 알리고, `AudioGuard`는 울릴 때 읽어서 고친다. **판정 로직은 공유한다.**"

지금은 공유도 안 하고 테스트도 없다. 그리고 §10은 "프리플라이트 판정 — 주어진 시스템 상태에서 어떤 경고가 나오는지"를 유닛 테스트 대상으로 명시했다.

이 앱에서 가장 중요한 로직이 가장 검증이 안 된 자리에 있다.

### E. 비목표로 못박은 기능이 들어왔다 · 높음

설계 문서 §3.2 비목표에 이렇게 적혀 있다.

> **클록 스타일·테마 다양화** — Awaken의 강점이지만 따라가지 않는다. 나이트스탠드는 한 가지 스타일만.

현재 `DesignSystem.swift`에 **테마 6종**이 있다 (아늑한 밤, 오트밀, 말차, 선셋, 라벤더, 원목). 각 테마마다 색 토큰이 여러 개라 이것만으로 145줄이고, 모든 뷰가 `theme.` 접두어에 묶여 있다.

테마 자체가 나쁜 게 아니다. **명시적으로 안 하기로 적어둔 걸 논의 없이 한 것**이 문제다. 이런 게 쌓이면 1단계를 며칠 써보고 2단계로 넘어가자던 순서가 무의미해진다. 실제로 커밋 로그를 보면 1·2·3단계가 며칠 만에 한꺼번에 들어왔다.

### F. `AlarmListModel`이 전부를 직접 만든다 · 높음

```swift
private let tonePlayer = TonePlayer()
public let playbackChain = PlaybackChain()
private let overlay = AlarmOverlayController()
private let powerManager = SystemPowerMatuta()
private let audioGuard = AudioGuard()
private let nightstand = NightstandController()
public let preflightEngine = PreflightEngine()
```

협력자 7개를 프로퍼티 초기화로 직접 생성한다. `store`만 주입 가능하다. 그래서 **이 클래스는 테스트할 수 없다** — 테스트를 돌리면 진짜 오디오 엔진이 켜지고 진짜 전원 이벤트가 예약되고 진짜 전체화면 창이 뜬다.

그런데 위 B와 C의 버그가 전부 이 클래스에 있다. 고쳐도 회귀를 막을 방법이 없다.

`playbackChain`과 `preflightEngine`이 `public`인 것도 캡슐화가 뚫린 신호다 — 뷰가 모델을 건너뛰고 내부를 직접 만지고 있다.

### G. 뷰 파일이 너무 크다 · 중간

`AlarmEditView.swift`가 871줄이고, 그 안의 `soundCardContent` 하나가 **185줄**(448–633)이다. 계획서가 "파일 하나에 책임 하나"를 요구했던 이유가 여기서 무너진다.

같은 파일 안에 거의 같은 함수가 넷 있다.

```
285: quickTimeChip(_ label:h:m:pm:)
717: presetChip(_ title:text:)
733: webPresetChip(_ title:url:)
749: radioPresetChip(_ title:url:)
```

뒤의 셋은 전달하는 값의 의미만 다르고 생긴 게 같다.

### H. 내장 사운드 이름이 두 갈래로 갈렸다 · 중간

`.builtIn(name:)`에 들어가는 문자열이 코드 8곳에 하드코딩돼 있는데, 기본값이 두 개다.

- `"Radar"` — `Alarm.swift:24` (기본 인자), `OmniboxParser.swift:17`
- `"Morning Harp"` — `AlarmStore.swift:28`, `AlarmListModel.swift:71`, `MatutaApp.swift:199`, `AlarmListView.swift:209`

`Alarm()`의 기본값은 Radar인데 실제로 알람을 만드는 자리는 전부 Morning Harp를 넘긴다. Radar 기본값은 사실상 죽은 코드다.

당장 소리가 안 나는 버그는 아니다 — `TonePattern.pattern(named:)`에 `default: return .morningHarp`가 있어서 오타가 나도 뭔가는 울린다. 하지만 **오타가 조용히 삼켜진다**는 뜻이기도 하다. 문자열로 식별자를 다루는 대신 타입으로 다뤄야 한다.

### I. 마케팅 문구가 코드에 들어와 있다 · 낮음

```
AlarmEditView.swift:146   // MARK: - 1. Tactile Time Sculptor Engine
AlarmEditView.swift:391   // MARK: - 4. Sound Deck (Icon-Only Minimal Bar)
TonePattern.swift:6       /// 배음(Harmonics)과 아르페지오 엔벨로프를 결합하여 스튜디오급 어쿠스틱 사운드를 생성한다.
TonePattern.swift:49      // MARK: - 스튜디오급 포근한 어쿠스틱 사운드스케이프
```

"Tactile Time Sculptor Engine"은 시각 입력 필드다. 이름이 하는 일을 설명하지 않고 홍보한다. 6개월 뒤에 이 파일을 여는 사람에게 아무 정보도 주지 않는다.

커밋 메시지도 같은 문제다.

> `feat: 바이브 코딩 완전 탈피 — 스마트 타임 스컬프터, 스튜디오 어쿠스틱 사운드스케이프, Raycast급 메뉴바 팝오버, 원자적 백업 스토리지, 실시간 스누즈 트래커, OLED 번인방지 나이트스탠드 2.0 완성`

커밋 하나에 기능 6개가 들어 있다. 나중에 "스누즈 트래커가 언제 들어왔지"를 찾을 때 이 커밋을 되돌리면 나머지 다섯 개가 같이 날아간다.

### J. 커밋되지 않은 임시 스크립트 6개 · 낮음

```
Spikes/test-audio.swift        Spikes/test-components.swift
Spikes/test-fire.swift         Spikes/test-full-flow.swift
Spikes/test-overlay.swift      Spikes/test_audio_guard.swift
```

전부 untracked다. 이름 규칙도 섞여 있다 (`test-audio` vs `test_audio_guard`). 이것들이 존재한다는 건 **검증하고 싶은 게 있었는데 유닛 테스트로 만들 수 없어서 스크립트로 때웠다**는 신호다 — 그 대상이 정확히 D에서 지적한 앱 타깃 모듈들이다.

### K. `PowerMatuta`라는 이름은 제 실수입니다 · 낮음

`PowerMatuta.swift`, `SystemPowerMatuta.swift`의 이름은 뜻이 통하지 않는다. 원래 설계의 이름은 `PowerWaker`("전원을 깨우는 것")였는데, 제가 이름을 Daybreak로 바꾸고 다시 Matuta로 바꿀 때 `Waker`를 기계적으로 일괄 치환하면서 `PowerWaker` → `PowerDaybreak` → `PowerMatuta`가 됐습니다.

제품명이 들어갈 자리가 아니었습니다. `PowerScheduler` 또는 `WakeScheduler`가 맞습니다.

---

## 3. 개선 기획

원칙 하나를 먼저 세운다. **덩치를 줄이는 것보다 검증 가능하게 만드는 것이 먼저다.** B와 C 같은 버그는 지금도 고칠 수 있지만, 테스트가 없으면 다음에 또 들어온다.

순서는 위험도 순이며, 각 단계는 그 자체로 커밋 가능해야 한다.

### 1단계 — 끌 수 없는 알람음부터 막는다

가장 위험하고 가장 작다.

- `PlaybackChain`에 세대 토큰(`generation: Int`)을 도입한다. `start()` 진입 시 증가시키고, 각 `await` 뒤에 자기 세대가 여전히 최신인지 확인한다. 아니면 방금 시작한 소스를 즉시 정지하고 빠져나온다
- `stop()`도 세대를 증가시켜 진행 중인 `start()`를 무효화한다
- 테스트: 느린 가짜 소스(`play()`가 `await`에서 멈춰 있는)를 주고, `start()` 도중에 `stop()`을 호출한 뒤 **어떤 소스도 재생 상태로 남지 않는지** 검증한다. 이게 이번 개선의 대표 테스트다
- `AlarmListModel.fire()`가 던지는 `Task`를 프로퍼티로 잡아두고 `dismissFiring()`에서 `cancel()`한다

### 2단계 — 스누즈를 진짜로 신뢰할 수 있게 만든다

- 스누즈 상태를 `Alarm` 바깥의 별도 값으로 모델링해 `MatutaCore`로 올린다. 예: `struct SnoozeState: Codable { let alarmID: UUID; let fireAt: Date }`
- `AlarmStore`가 이걸 같이 저장한다. 앱 시작 시 복원하고, 이미 지난 스누즈면 즉시 발화하거나 버린다 (어느 쪽인지 정하고 문서에 적을 것)
- **다음 발화 시각을 한 곳에서만 계산한다.** 지금 `nextFireDate`와 `reschedule()`이 따로 계산하는 걸 하나로 합친다. 스누즈가 걸려 있으면 그게 다음 발화다
- `reschedule()`이 그 통합된 값으로 `scheduleWake`를 건다 → 스누즈 중 절전에서도 깨어난다
- 테스트: 스누즈가 걸린 상태에서 "다음 발화 시각"이 스누즈 시각인지, 스누즈 저장·복원이 왕복하는지, 지난 스누즈가 어떻게 처리되는지

### 3단계 — 신뢰성 로직을 코어로 내린다

`AudioGuard`와 `PreflightEngine`을 통째로 옮기는 게 아니라 **판정과 실행을 가른다.**

- `MatutaCore`에 시스템 상태를 나타내는 값 타입을 만든다. 예: `struct AudioSnapshot { outputDeviceName: String; isHeadphones: Bool; volume: Double; isMuted: Bool }`
- 판정 함수를 코어의 순수 함수로 만든다: `Preflight.evaluate(audio: AudioSnapshot, wakeScheduled: Bool, source: SoundSourceRef) -> PreflightReport`. 시스템을 만지지 않는다
- 앱 타깃에는 스냅샷을 읽고 실제로 기기를 바꾸는 얇은 어댑터만 남긴다
- 설계 문서 §6.1이 요구한 "판정 로직 공유"가 이 지점에서 자연히 달성된다 — `AudioGuard`도 같은 스냅샷을 읽는다
- 테스트: 이어폰이 연결된 스냅샷, 볼륨 0인 스냅샷, 뮤트인 스냅샷, 깨우기 예약 실패 상태 각각에서 어떤 경고가 나오는지
- 이 단계가 끝나면 `Spikes/test_audio_guard.swift` 같은 임시 스크립트를 지울 수 있다

### 4단계 — 결정했던 옴니박스로 되돌린다

여기서 제품 논의가 한 번 필요하다. **A안을 이미 만들어놨으니 그냥 갈 수도 있다.** 다만 그러려면 설계 문서 §4 원칙 3과 §5.3을 고쳐서 "탭 방식으로 간다"고 명시해야 한다. 결정이 바뀐 것과 결정이 흘러간 것은 다르다.

옴니박스로 되돌린다면:

- 사운드 영역 최상단에 입력 칸 하나 + 그 아래 최근 사용 칩 4개
- 붙여넣기·드롭·검색을 `OmniboxParser.parse`가 판별하고, 판별 결과를 확정 전 칩으로 보여준다 (설계 문서 §8.3)
- 현재의 6탭은 "찾아보기" 버튼 뒤로 접는다. 만든 코드를 버리지 않고 자리만 옮기는 것이다
- 아이콘 전용 바는 어느 쪽으로 가든 **글자 라벨을 되살린다.** 툴팁은 라벨이 아니다

### 5단계 — 큰 파일을 쪼갠다

기능 변경 없이 구조만 손대는 단계라 마지막에 둔다. 앞 단계에서 테스트가 붙은 뒤에 하는 게 안전하다.

- `AlarmEditView`(871줄)를 섹션별 뷰로 분리: `TimeFieldView`, `WeekdayPickerView`, `SoundPickerView`, `VolumeOptionsView`. 각각 별도 파일
- `presetChip` / `webPresetChip` / `radioPresetChip`을 하나로 합친다
- `AlarmListModel`의 협력자를 생성자 주입으로 바꾼다. 기본 인자를 주면 호출부는 그대로 두면서 테스트에서만 가짜를 넣을 수 있다
- `playbackChain`, `preflightEngine`의 `public`을 걷어내고 모델의 메서드로 감싼다

### 6단계 — 정리

- 내장 사운드 이름을 문자열에서 타입으로 바꾼다. `enum BuiltInTone: String, CaseIterable`를 `MatutaCore`에 두고 `SoundSourceRef.builtIn(BuiltInTone)`으로 받는다. 기본값을 하나로 통일한다 (`Radar`인지 `Morning Harp`인지 정할 것)
- `PowerMatuta` / `SystemPowerMatuta` → `WakeScheduler` / `SystemWakeScheduler`
- 마케팅성 주석을 하는 일 설명으로 교체한다
- `Spikes/test-*.swift` 중 3단계에서 유닛 테스트로 흡수된 것은 삭제하고, 남는 것은 이름 규칙을 맞춰 커밋한다
- 앞으로 커밋은 한 가지 변경만 담는다

---

## 4. 하지 말 것

- **전면 재작성.** 기반은 멀쩡하다. 위 단계는 전부 국소 수정이다
- **테마 6종 삭제.** 이미 만들었고 동작한다. 비목표였다는 사실만 설계 문서에 반영해서 결정을 명시적으로 바꾸면 된다. 다만 **여기서 더 늘리지 않는다**
- **디자인 리터치.** 이번 라운드는 신뢰성과 검증 가능성만 다룬다

## 5. 완료 판정

- [ ] `start()` 도중 `stop()`을 호출해도 소리가 남지 않는다 — 테스트로 증명
- [ ] 스누즈 중 Mac이 절전에 들어가도 깨어나서 울린다 — 실제로 재현해볼 것
- [ ] 스누즈 중 앱을 재시작해도 스누즈가 살아 있다
- [ ] 프리플라이트 판정이 `MatutaCore`에 있고 상태별 테스트가 붙어 있다
- [ ] 사운드 선택 방식이 코드와 설계 문서에서 일치한다
- [ ] `Sources/Matuta`에 800줄 넘는 파일이 없다
- [ ] `swift test`가 통과한다
