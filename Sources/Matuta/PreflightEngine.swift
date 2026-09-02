import Foundation
import MatutaCore

public struct PreflightIssue: Identifiable, Sendable {
    public enum Severity: Sendable {
        case info
        case warning
        case error
    }

    public let id = UUID()
    public let severity: Severity
    public let title: String
    public let detail: String

    public init(severity: Severity, title: String, detail: String) {
        self.severity = severity
        self.title = title
        self.detail = detail
    }
}

public struct PreflightReport: Sendable {
    public let statusText: String
    public let isReady: Bool
    public let issues: [PreflightIssue]

    public init(statusText: String, isReady: Bool, issues: [PreflightIssue]) {
        self.statusText = statusText
        self.isReady = isReady
        self.issues = issues
    }
}

@MainActor
public final class PreflightEngine {
    private let audioGuard: AudioGuard

    public init(audioGuard: AudioGuard = AudioGuard()) {
        self.audioGuard = audioGuard
    }

    public func evaluate(alarm: Alarm?) async -> PreflightReport {
        var issues: [PreflightIssue] = []

        // 1. 오디오 장치 및 볼륨 점검
        var deviceName = "스피커"
        var volumePercent = 70
        var isHeadphones = false

        if let deviceID = audioGuard.getDefaultOutputDeviceID() {
            deviceName = audioGuard.getDeviceName(deviceID: deviceID)
            let vol = audioGuard.getVolume(deviceID: deviceID)
            volumePercent = Int(vol * 100)
            let muted = audioGuard.getMute(deviceID: deviceID)
            isHeadphones = audioGuard.isHeadphones(deviceID: deviceID)

            if muted {
                issues.append(PreflightIssue(
                    severity: .warning,
                    title: "시스템 오디오 음소거 상태",
                    detail: "알람 시각에 자동으로 음소거가 해제되고 소리가 울립니다."
                ))
            }

            if vol < 0.3 {
                issues.append(PreflightIssue(
                    severity: .warning,
                    title: "시스템 볼륨이 낮음 (\(volumePercent)%)",
                    detail: "알람 발화 시 알람 설정 볼륨으로 자동 확보됩니다."
                ))
            }

            if isHeadphones {
                issues.append(PreflightIssue(
                    severity: .info,
                    title: "이어폰/헤드폰 연결됨 (\(deviceName))",
                    detail: "알람 발화 시 내장 스피커로 안전하게 자동 전환됩니다."
                ))
            }
        }

        // 2. 사운드 소스 점검
        if let alarm = alarm {
            let source = SoundSourceFactory.makeSource(for: alarm.source)
            let result = await source.preflight()
            if case .warning(let msg) = result {
                issues.append(PreflightIssue(
                    severity: .warning,
                    title: "사운드 소스 주의",
                    detail: "\(msg) (실패 시 Radar 백업음으로 대체)"
                ))
            } else if case .error(let msg) = result {
                issues.append(PreflightIssue(
                    severity: .error,
                    title: "사운드 소스 오류",
                    detail: "\(msg) (Radar 백업음이 대신 울립니다)"
                ))
            }
        }

        let isReady = !issues.contains(where: { $0.severity == .error })
        let summary: String
        if isHeadphones {
            summary = "스피커 자동전환 대기 · 볼륨 \(volumePercent)% · 절전 깨우기 예약됨"
        } else {
            summary = "\(deviceName) · 볼륨 \(volumePercent)% · 절전 깨우기 예약됨"
        }

        return PreflightReport(statusText: summary, isReady: isReady, issues: issues)
    }
}
