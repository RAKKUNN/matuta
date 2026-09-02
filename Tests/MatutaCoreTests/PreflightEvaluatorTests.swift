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
    #expect(report.summary.contains("모든 준비 완료"))
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
    #expect(report.warnings[0].message.contains("내장 스피커로 자동 전환"))
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
    #expect(reportMuted.warnings.contains { $0.message.contains("음소거") })

    let audioLow = AudioSnapshot(
        defaultDeviceName: "MacBook Pro 스피커",
        isHeadphones: false,
        volume: 0.15,
        isMuted: false
    )
    let reportLow = PreflightEvaluator.evaluate(audio: audioLow, wakeScheduled: true, alarm: nil)
    #expect(reportLow.isSafe == false)
    #expect(reportLow.warnings.contains { $0.message.contains("볼륨이 낮습니다") })
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
    #expect(report.warnings.contains { $0.message.contains("전원 자동 깨우기") })
}
