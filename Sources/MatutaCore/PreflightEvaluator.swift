import Foundation

public struct PreflightWarning: Sendable, Equatable, Identifiable {
    public var id: Kind { kind }
    public let kind: Kind
    public let message: String
    public let severity: Severity
    public let icon: String
    public let actionLabel: String?

    public enum Kind: String, Sendable, Equatable {
        case headphones
        case muted
        case lowVolume
        case wakeNotScheduled
        case automationDenied
    }

    public enum Severity: Sendable, Equatable {
        case warning
        case info
    }

    public init(
        kind: Kind,
        message: String,
        severity: Severity = .warning,
        icon: String,
        actionLabel: String? = nil
    ) {
        self.kind = kind
        self.message = message
        self.severity = severity
        self.icon = icon
        self.actionLabel = actionLabel
    }
}

/// UI 뱃지 렌더링용 구조체
public struct PreflightBadgeItem: Sendable, Equatable, Identifiable {
    public var id: String { label }
    public let icon: String
    public let label: String
    public let severity: PreflightWarning.Severity
    public let actionKind: PreflightWarning.Kind?
    public let actionLabel: String?

    public init(
        icon: String,
        label: String,
        severity: PreflightWarning.Severity,
        actionKind: PreflightWarning.Kind? = nil,
        actionLabel: String? = nil
    ) {
        self.icon = icon
        self.label = label
        self.severity = severity
        self.actionKind = actionKind
        self.actionLabel = actionLabel
    }
}

public struct PreflightReport: Sendable, Equatable {
    public let isSafe: Bool
    public let warnings: [PreflightWarning]
    public let summary: String
    public let audio: AudioSnapshot

    public init(
        isSafe: Bool,
        warnings: [PreflightWarning],
        summary: String,
        audio: AudioSnapshot = AudioSnapshot(defaultDeviceName: "기본 기기", isHeadphones: false, volume: 0.5, isMuted: false)
    ) {
        self.isSafe = isSafe
        self.warnings = warnings
        self.summary = summary
        self.audio = audio
    }

    /// 오디오 출력 기기 뱃지 (헤드폰 연결 시 .info 중립 뱃지, 미연결 시 정상 뱃지)
    public var outputDeviceBadge: PreflightBadgeItem {
        if let hp = warnings.first(where: { $0.kind == .headphones }) {
            return PreflightBadgeItem(
                icon: hp.icon,
                label: hp.message,
                severity: hp.severity,
                actionKind: hp.kind,
                actionLabel: hp.actionLabel
            )
        }
        return PreflightBadgeItem(
            icon: "speaker.wave.2.fill",
            label: "내장 스피커 준비됨",
            severity: .info,
            actionKind: nil,
            actionLabel: nil
        )
    }

    /// 볼륨 & 뮤트 뱃지 (음소거/저볼륨 시 .warning 주황 뱃지, 정상 시 예고형 안전 뱃지)
    public var volumeGuardBadge: PreflightBadgeItem {
        if let volWarn = warnings.first(where: { $0.kind == .muted || $0.kind == .lowVolume }) {
            return PreflightBadgeItem(
                icon: volWarn.icon,
                label: volWarn.message,
                severity: volWarn.severity,
                actionKind: volWarn.kind,
                actionLabel: volWarn.actionLabel
            )
        }
        return PreflightBadgeItem(
            icon: "shield.checkmark.fill",
            label: "울릴 때 스피커 보호 전환",
            severity: .info,
            actionKind: nil,
            actionLabel: nil
        )
    }

    /// 첫 번째 경고(Warning) — UI 주황색 알림 타겟
    public var primaryWarning: PreflightWarning? {
        warnings.first { $0.severity == .warning }
    }

    /// 첫 번째 안내(Info) — UI 중립/보조 알림 타겟
    public var primaryInfo: PreflightWarning? {
        warnings.first { $0.severity == .info }
    }
}

/// 시스템 I/O 없이 순수 입력(오디오 스냅샷, 전원 예약 상태, 알람 설정)만으로 사전 진단을 내리는 순수 평가기.
public struct PreflightEvaluator: Sendable {
    public static func evaluate(
        audio: AudioSnapshot,
        wakeScheduled: Bool,
        isSleepPrevented: Bool = false,
        alarm: Alarm?,
        automation: AutomationSnapshot = .notRequired
    ) -> PreflightReport {
        var warnings: [PreflightWarning] = []

        // 1. 헤드폰/에어팟 감지: 알람 발화 시 AudioGuard가 내장 스피커로 자동 전환하므로 .info
        if audio.isHeadphones {
            warnings.append(PreflightWarning(
                kind: .headphones,
                message: "이어폰 연결됨 (울릴 때 내장 스피커로 자동 전환)",
                severity: .info,
                icon: "headphones",
                actionLabel: "스피커로 전환"
            ))
        }

        // 2. 볼륨 & 음소거 상태: 현재 상태가 무음이므로 사용자 인지가 필요한 .warning
        if audio.isMuted {
            warnings.append(PreflightWarning(
                kind: .muted,
                message: "시스템이 음소거 상태입니다 (울릴 때 자동 해제)",
                severity: .warning,
                icon: "speaker.slash.fill",
                actionLabel: "70%로 해제"
            ))
        } else if audio.volume < 0.3 {
            warnings.append(PreflightWarning(
                kind: .lowVolume,
                message: "현재 볼륨이 낮습니다 (\(Int(audio.volume * 100))%)",
                severity: .warning,
                icon: "speaker.wave.1.fill",
                actionLabel: "70%로 조정"
            ))
        }

        // 3. 전원 깨우기 상태 (나이트스탠드 등 절전 방지 활성이거나 전원 예약이 되어 있는 경우 정상)
        if let alarm, alarm.isEnabled && !wakeScheduled && !isSleepPrevented {
            warnings.append(PreflightWarning(
                kind: .wakeNotScheduled,
                message: "전원 자동 깨우기가 예약되지 않았습니다",
                severity: .warning,
                icon: "bolt.slash.fill",
                actionLabel: nil
            ))
        }

        // 4. 외부 앱 자동화 권한.
        //    볼륨·출력기기와 달리 AudioGuard가 발화 시점에 고쳐줄 수 없다.
        //    권한이 없으면 사용자가 고른 음악은 재생되지 않는다(백업음만 울린다).
        if !automation.canPlay {
            let target = automation.targetName
            switch automation.status {
            case .denied:
                warnings.append(PreflightWarning(
                    kind: .automationDenied,
                    message: "\(target) 제어 권한이 꺼져 있습니다 (백업음만 울립니다)",
                    severity: .warning,
                    icon: "lock.slash.fill",
                    actionLabel: "설정 열기"
                ))
            case .notDetermined:
                warnings.append(PreflightWarning(
                    kind: .automationDenied,
                    message: "\(target) 제어 권한이 아직 허용되지 않았습니다",
                    severity: .warning,
                    icon: "lock.open.fill",
                    actionLabel: "권한 허용"
                ))
            case .appNotInstalled:
                warnings.append(PreflightWarning(
                    kind: .automationDenied,
                    message: "\(target) 앱이 설치되어 있지 않습니다 (백업음만 울립니다)",
                    severity: .warning,
                    icon: "questionmark.app.fill",
                    actionLabel: nil
                ))
            case .notRequired, .granted, .unknown:
                break
            }
        }

        let isSafe = warnings.filter({ $0.severity == .warning }).isEmpty
        let summary: String
        if isSafe {
            summary = "모든 준비 완료 · 내장 스피커 보호 · 절전 깨우기 예약됨"
        } else {
            summary = warnings.map(\.message).joined(separator: " · ")
        }

        return PreflightReport(isSafe: isSafe, warnings: warnings, summary: summary, audio: audio)
    }
}
