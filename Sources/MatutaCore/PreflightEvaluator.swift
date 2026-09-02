import Foundation

public struct PreflightWarning: Sendable, Equatable, Identifiable {
    public var id: String { message }
    public let message: String
    public let severity: Severity

    public enum Severity: Sendable, Equatable {
        case warning
        case info
    }

    public init(message: String, severity: Severity = .warning) {
        self.message = message
        self.severity = severity
    }
}

public struct PreflightReport: Sendable, Equatable {
    public let isSafe: Bool
    public let warnings: [PreflightWarning]
    public let summary: String

    public init(isSafe: Bool, warnings: [PreflightWarning], summary: String) {
        self.isSafe = isSafe
        self.warnings = warnings
        self.summary = summary
    }
}

/// 시스템 I/O 없이 순수 입력(오디오 스냅샷, 전원 예약 상태, 알람 설정)만으로 사전 진단을 내리는 순수 평가기.
public struct PreflightEvaluator: Sendable {
    public static func evaluate(
        audio: AudioSnapshot,
        wakeScheduled: Bool,
        alarm: Alarm?
    ) -> PreflightReport {
        var warnings: [PreflightWarning] = []

        // 1. 헤드폰/에어팟 감지
        if audio.isHeadphones {
            warnings.append(PreflightWarning(
                message: "이어폰/헤드폰(\(audio.defaultDeviceName))이 연결되어 있습니다. 알람 시 내장 스피커로 자동 전환됩니다.",
                severity: .info
            ))
        }

        // 2. 볼륨 & 음소거 상태
        if audio.isMuted {
            warnings.append(PreflightWarning(
                message: "시스템이 음소거 상태입니다. 알람 발화 시 자동으로 해제됩니다.",
                severity: .warning
            ))
        } else if audio.volume < 0.3 {
            warnings.append(PreflightWarning(
                message: "현재 볼륨이 낮습니다(\(Int(audio.volume * 100))%). 알람 시 설정 볼륨으로 확보됩니다.",
                severity: .warning
            ))
        }

        // 3. 전원 깨우기 상태
        if let alarm, alarm.isEnabled && !wakeScheduled {
            warnings.append(PreflightWarning(
                message: "전원 자동 깨우기가 예약되지 않았습니다.",
                severity: .warning
            ))
        }

        let isSafe = warnings.filter({ $0.severity == .warning }).isEmpty
        let summary: String
        if isSafe {
            summary = "모든 준비 완료 · 내장 스피커 보호 · 절전 깨우기 예약됨"
        } else {
            summary = warnings.map(\.message).joined(separator: " · ")
        }

        return PreflightReport(isSafe: isSafe, warnings: warnings, summary: summary)
    }
}
