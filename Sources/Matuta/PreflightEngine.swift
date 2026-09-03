import Foundation
import MatutaCore

/// UI 및 나이트스탠드에 시스템 진단 결과를 제공하는 얇은 앱 어댑터.
///
/// 설계 문서 §6.1 & 진단서 2.D:
/// 순수 판정 로직은 `PreflightEvaluator`(MatutaCore)에 맡기고,
/// 이 클래스는 시스템 하드웨어 스냅샷을 취합하여 넘기는 역할만 수행한다.
@MainActor
public final class PreflightEngine {
    private let audioGuard: AudioGuard
    private let wakeScheduler: SystemWakeScheduler

    public init(audioGuard: AudioGuard = AudioGuard(), wakeScheduler: SystemWakeScheduler = SystemWakeScheduler()) {
        self.audioGuard = audioGuard
        self.wakeScheduler = wakeScheduler
    }

    public func evaluate(alarm: Alarm?, isSleepPrevented: Bool = false) -> PreflightReport {
        let snapshot = audioGuard.captureSnapshot()
        let isWakeArmed = wakeScheduler.isWakeScheduled
        let automation = alarm.map { AutomationPermission.snapshot(for: $0.source) }
            ?? .notRequired
        return PreflightEvaluator.evaluate(
            audio: snapshot,
            wakeScheduled: isWakeArmed,
            isSleepPrevented: isSleepPrevented,
            alarm: alarm,
            automation: automation
        )
    }

    public func switchToBuiltInSpeaker() {
        audioGuard.switchToBuiltInSpeaker()
    }

    public func setVolumeToSafeLevel(_ volume: Float = 0.7) {
        audioGuard.setVolumeToSafeLevel(volume)
    }

    /// 자동화 권한 경고를 눌렀을 때: 미결정이면 권한 요청, 거부 상태면 시스템 설정을 연다.
    public func resolveAutomation(for alarm: Alarm?) {
        guard let alarm else { return }
        AutomationPermission.resolve(for: alarm.source)
    }
}
