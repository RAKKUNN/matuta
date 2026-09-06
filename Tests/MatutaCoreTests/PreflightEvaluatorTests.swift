import Testing
import Foundation
@testable import MatutaCore

@Test("정상 상태에서는 경고 없이 안전(isSafe=true) 판정을 내린다")
func testPreflightSafeState() {
    let audio = AudioSnapshot(
        defaultDeviceName: "MacBook Pro 스피커",
        isHeadphones: false,
        volume: 0.8,
        isMuted: false
    )
    let alarm = Alarm(hour: 7, minute: 0, isEnabled: true)

    let report = PreflightEvaluator.evaluate(audio: audio, wakeScheduled: true, alarm: alarm)

    #expect(report.isSafe == true)
    #expect(report.warnings.isEmpty)
    #expect(report.summaryTexts.contains(.allReady))
}

@Test("헤드폰/에어팟이 연결된 경우 정보성(info) 알림을 생성하고 안전 판정을 유지한다")
func testPreflightHeadphonesState() {
    let audio = AudioSnapshot(
        defaultDeviceName: "AirPods Pro",
        isHeadphones: true,
        volume: 0.7,
        isMuted: false
    )
    let alarm = Alarm(hour: 7, minute: 0, isEnabled: true)

    let report = PreflightEvaluator.evaluate(audio: audio, wakeScheduled: true, alarm: alarm)

    #expect(report.isSafe == true)
    #expect(report.warnings.count == 1)
    #expect(report.warnings[0].severity == .info)
    #expect(report.warnings[0].text == .headphonesConnected)
    #expect(report.warnings[0].actionText == .switchToSpeaker)
}

@Test("음소거 또는 볼륨이 30% 미만인 경우 경고(warning)를 생성한다")
func testPreflightMutedOrLowVolumeState() {
    let audioMuted = AudioSnapshot(
        defaultDeviceName: "MacBook Pro 스피커",
        isHeadphones: false,
        volume: 0.8,
        isMuted: true
    )
    let reportMuted = PreflightEvaluator.evaluate(audio: audioMuted, wakeScheduled: true, alarm: nil)
    #expect(reportMuted.isSafe == false)
    #expect(reportMuted.warnings.contains { $0.text == .systemMuted })
    #expect(reportMuted.warnings.contains { $0.actionText == .unmuteToSafeVolume })

    let audioLow = AudioSnapshot(
        defaultDeviceName: "MacBook Pro 스피커",
        isHeadphones: false,
        volume: 0.15,
        isMuted: false
    )
    let reportLow = PreflightEvaluator.evaluate(audio: audioLow, wakeScheduled: true, alarm: nil)
    #expect(reportLow.isSafe == false)
    #expect(reportLow.warnings.contains { $0.text == .lowVolume(percent: 15) })
    #expect(reportLow.warnings.contains { $0.actionText == .adjustToSafeVolume })
}

@Test("켜진 알람이 있는데 전원 깨우기가 예약되지 않은 경우 경고를 생성한다")
func testPreflightWakeNotScheduledState() {
    let audio = AudioSnapshot(
        defaultDeviceName: "MacBook Pro 스피커",
        isHeadphones: false,
        volume: 0.7,
        isMuted: false
    )
    let alarm = Alarm(hour: 7, minute: 0, isEnabled: true)

    let report = PreflightEvaluator.evaluate(audio: audio, wakeScheduled: false, alarm: alarm)
    #expect(report.isSafe == false)
    #expect(report.warnings.contains { $0.text == .wakeNotScheduled })
}

@Test("헤드폰 연결 시 outputDeviceBadge는 .info이며 안전(isSafe=true) 상태를 유지한다")
func testPreflightHeadphonesBadgeIsInfo() {
    let audio = AudioSnapshot(
        defaultDeviceName: "AirPods Pro",
        isHeadphones: true,
        volume: 0.8,
        isMuted: false
    )
    let report = PreflightEvaluator.evaluate(audio: audio, wakeScheduled: true, isSleepPrevented: true, alarm: nil)
    #expect(report.isSafe == true)
    #expect(report.outputDeviceBadge.severity == .info)
    #expect(report.outputDeviceBadge.actionKind == .headphones)
    #expect(report.outputDeviceBadge.text == .headphonesConnected)
    #expect(report.outputDeviceBadge.actionText == .switchToSpeaker)
    #expect(report.volumeGuardBadge.severity == .info)
    #expect(report.volumeGuardBadge.text == .speakerProtectionReady)
    #expect(report.primaryWarning == nil)
    #expect(report.primaryInfo?.kind == .headphones)
}

@Test("음소거 시 volumeGuardBadge는 .warning이며 원클릭 복구 actionKind가 .muted이다")
func testPreflightMutedBadgeIsWarning() {
    let audio = AudioSnapshot(
        defaultDeviceName: "내장 스피커",
        isHeadphones: false,
        volume: 0.8,
        isMuted: true
    )
    let report = PreflightEvaluator.evaluate(audio: audio, wakeScheduled: true, isSleepPrevented: true, alarm: nil)
    #expect(report.isSafe == false)
    #expect(report.volumeGuardBadge.severity == .warning)
    #expect(report.volumeGuardBadge.actionKind == .muted)
    #expect(report.volumeGuardBadge.text == .systemMuted)
    #expect(report.volumeGuardBadge.actionText == .unmuteToSafeVolume)
    #expect(report.primaryWarning?.kind == .muted)
}


// MARK: - 외부 앱 자동화 권한 (Spotify / 음악)

@Test("자동화가 필요 없는 소스는 경고를 만들지 않는다")
func automationNotRequiredProducesNoWarning() {
    let report = PreflightEvaluator.evaluate(
        audio: AudioSnapshot(defaultDeviceName: "내장 스피커", isHeadphones: false, volume: 0.7, isMuted: false),
        wakeScheduled: true,
        alarm: Alarm(hour: 7, minute: 0),
        automation: .notRequired
    )
    #expect(report.warnings.contains { $0.kind == .automationDenied } == false)
    #expect(report.isSafe)
}

@Test("자동화 권한이 거부되면 경고를 만들고 안전 판정을 깬다")
func automationDeniedProducesWarning() {
    let report = PreflightEvaluator.evaluate(
        audio: AudioSnapshot(defaultDeviceName: "내장 스피커", isHeadphones: false, volume: 0.7, isMuted: false),
        wakeScheduled: true,
        alarm: Alarm(hour: 7, minute: 0),
        automation: AutomationSnapshot(target: .spotify, status: .denied)
    )
    let warning = report.warnings.first { $0.kind == .automationDenied }
    #expect(warning?.severity == .warning)
    #expect(warning?.text == .automationDenied(target: .spotify))
    #expect(warning?.actionText == .openSettings)
    #expect(report.isSafe == false)
}

@Test("권한을 아직 묻지 않은 상태는 허용 요청 액션을 제공한다")
func automationNotDeterminedOffersAction() {
    let report = PreflightEvaluator.evaluate(
        audio: AudioSnapshot(defaultDeviceName: "내장 스피커", isHeadphones: false, volume: 0.7, isMuted: false),
        wakeScheduled: true,
        alarm: Alarm(hour: 7, minute: 0),
        automation: AutomationSnapshot(target: .appleMusic, status: .notDetermined)
    )
    let warning = report.warnings.first { $0.kind == .automationDenied }
    #expect(warning?.text == .automationNotDetermined(target: .appleMusic))
    #expect(warning?.actionText == .requestPermission)
}

@Test("대상 앱이 설치되어 있지 않으면 권한 요청이 아니라 설치 안내를 한다")
func automationAppNotInstalledHasNoAction() {
    let report = PreflightEvaluator.evaluate(
        audio: AudioSnapshot(defaultDeviceName: "내장 스피커", isHeadphones: false, volume: 0.7, isMuted: false),
        wakeScheduled: true,
        alarm: Alarm(hour: 7, minute: 0),
        automation: AutomationSnapshot(target: .spotify, status: .appNotInstalled)
    )
    let warning = report.warnings.first { $0.kind == .automationDenied }
    #expect(warning != nil)
    #expect(warning?.text == .automationNotInstalled(target: .spotify))
    // 설치가 안 된 건 앱이 대신 고쳐줄 수 없다 — 누를 수 있는 액션을 주면 안 된다.
    #expect(warning?.actionText == nil)
}

@Test("권한을 판별할 수 없는 상태(대상 앱 미실행)는 경고하지 않는다")
func automationUnknownProducesNoWarning() {
    let report = PreflightEvaluator.evaluate(
        audio: AudioSnapshot(defaultDeviceName: "내장 스피커", isHeadphones: false, volume: 0.7, isMuted: false),
        wakeScheduled: true,
        alarm: Alarm(hour: 7, minute: 0),
        automation: AutomationSnapshot(target: .spotify, status: .unknown)
    )
    #expect(report.warnings.contains { $0.kind == .automationDenied } == false)
    #expect(report.isSafe)
}

// MARK: - 로그인 시 자동 실행

@Test("로그인 자동 실행이 꺼져 있으면 경고하고 안전 판정을 깬다")
func notLaunchAtLoginProducesWarning() {
    let report = PreflightEvaluator.evaluate(
        audio: AudioSnapshot(defaultDeviceName: "내장 스피커", isHeadphones: false, volume: 0.7, isMuted: false),
        wakeScheduled: true,
        alarm: Alarm(hour: 7, minute: 0),
        launchesAtLogin: false
    )
    let warning = report.warnings.first { $0.kind == .notLaunchAtLogin }
    #expect(warning?.severity == .warning)
    #expect(warning?.actionText != nil)
    #expect(report.isSafe == false)
}

@Test("로그인 자동 실행이 켜져 있으면 경고하지 않는다")
func launchAtLoginProducesNoWarning() {
    let report = PreflightEvaluator.evaluate(
        audio: AudioSnapshot(defaultDeviceName: "내장 스피커", isHeadphones: false, volume: 0.7, isMuted: false),
        wakeScheduled: true,
        alarm: Alarm(hour: 7, minute: 0),
        launchesAtLogin: true
    )
    #expect(report.warnings.contains { $0.kind == .notLaunchAtLogin } == false)
    #expect(report.isSafe)
}

@Test("켜진 알람이 없으면 로그인 자동 실행을 따지지 않는다")
func noEnabledAlarmSkipsLaunchAtLoginCheck() {
    // 알람이 없으면 앱이 안 떠 있어도 잃을 것이 없다.
    let report = PreflightEvaluator.evaluate(
        audio: AudioSnapshot(defaultDeviceName: "내장 스피커", isHeadphones: false, volume: 0.7, isMuted: false),
        wakeScheduled: true,
        alarm: nil,
        launchesAtLogin: false
    )
    #expect(report.warnings.contains { $0.kind == .notLaunchAtLogin } == false)
}
