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
    private let powerManager: SystemPowerMatuta

    public init(audioGuard: AudioGuard = AudioGuard(), powerManager: SystemPowerMatuta = SystemPowerMatuta()) {
        self.audioGuard = audioGuard
        self.powerManager = powerManager
    }

    public func evaluate(alarm: Alarm?) async -> PreflightReport {
        let snapshot = audioGuard.captureSnapshot()
        let isWakeArmed = powerManager.isWakeScheduled
        return PreflightEvaluator.evaluate(
            audio: snapshot,
            wakeScheduled: isWakeArmed,
            alarm: alarm
        )
    }
}
