import Foundation

public struct PreflightWarning: Sendable, Equatable, Identifiable {
    public var id: Kind { kind }
    public let kind: Kind
    public let text: LocalizedText
    public let severity: Severity
    public let icon: String
    public let actionText: LocalizedText?

    public var message: String {
        Localizer.string(text, .korean)
    }

    public var actionLabel: String? {
        actionText.map { Localizer.string($0, .korean) }
    }

    public enum Kind: String, Sendable, Equatable {
        case headphones
        case muted
        case lowVolume
        case wakeNotScheduled
        case automationDenied
        case notLaunchAtLogin
    }

    public enum Severity: Sendable, Equatable {
        case warning
        case info
    }

    public init(
        kind: Kind,
        text: LocalizedText,
        severity: Severity = .warning,
        icon: String,
        actionText: LocalizedText? = nil
    ) {
        self.kind = kind
        self.text = text
        self.severity = severity
        self.icon = icon
        self.actionText = actionText
    }
}

/// UI 뱃지 렌더링용 구조체
public struct PreflightBadgeItem: Sendable, Equatable, Identifiable {
    public var id: String { "\(text.hashValue)_\(severity)" }
    public let icon: String
    public let text: LocalizedText
    public let severity: PreflightWarning.Severity
    public let actionKind: PreflightWarning.Kind?
    public let actionText: LocalizedText?

    public var label: String {
        Localizer.string(text, .korean)
    }

    public var actionLabel: String? {
        actionText.map { Localizer.string($0, .korean) }
    }

    public init(
        icon: String,
        text: LocalizedText,
        severity: PreflightWarning.Severity,
        actionKind: PreflightWarning.Kind? = nil,
        actionText: LocalizedText? = nil
    ) {
        self.icon = icon
        self.text = text
        self.severity = severity
        self.actionKind = actionKind
        self.actionText = actionText
    }
}

public struct PreflightReport: Sendable, Equatable {
    public let isSafe: Bool
    public let warnings: [PreflightWarning]
    public let summaryTexts: [LocalizedText]
    public let audio: AudioSnapshot

    public var summary: String {
        summaryTexts.map { Localizer.string($0, .korean) }.joined(separator: " · ")
    }

    public init(
        isSafe: Bool,
        warnings: [PreflightWarning],
        summaryTexts: [LocalizedText],
        audio: AudioSnapshot = AudioSnapshot(defaultDeviceName: "기본 기기", isHeadphones: false, volume: 0.5, isMuted: false)
    ) {
        self.isSafe = isSafe
        self.warnings = warnings
        self.summaryTexts = summaryTexts
        self.audio = audio
    }

    /// 오디오 출력 기기 뱃지 (헤드폰 연결 시 .info 중립 뱃지, 미연결 시 정상 뱃지)
    public var outputDeviceBadge: PreflightBadgeItem {
        if let hp = warnings.first(where: { $0.kind == .headphones }) {
            return PreflightBadgeItem(
                icon: hp.icon,
                text: hp.text,
                severity: hp.severity,
                actionKind: hp.kind,
                actionText: hp.actionText
            )
        }
        return PreflightBadgeItem(
            icon: "speaker.wave.2.fill",
            text: .builtInSpeakerReady,
            severity: .info,
            actionKind: nil,
            actionText: nil
        )
    }

    /// 볼륨 & 뮤트 뱃지 (음소거/저볼륨 시 .warning 주황 뱃지, 정상 시 예고형 안전 뱃지)
    public var volumeGuardBadge: PreflightBadgeItem {
        if let volWarn = warnings.first(where: { $0.kind == .muted || $0.kind == .lowVolume }) {
            return PreflightBadgeItem(
                icon: volWarn.icon,
                text: volWarn.text,
                severity: volWarn.severity,
                actionKind: volWarn.kind,
                actionText: volWarn.actionText
            )
        }
        return PreflightBadgeItem(
            icon: "shield.checkmark.fill",
            text: .speakerProtectionReady,
            severity: .info,
            actionKind: nil,
            actionText: nil
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
        automation: AutomationSnapshot = .notRequired,
        launchesAtLogin: Bool = true
    ) -> PreflightReport {
        var warnings: [PreflightWarning] = []

        // 1. 헤드폰/에어팟 감지: 알람 발화 시 AudioGuard가 내장 스피커로 자동 전환하므로 .info
        if audio.isHeadphones {
            warnings.append(PreflightWarning(
                kind: .headphones,
                text: .headphonesConnected,
                severity: .info,
                icon: "headphones",
                actionText: .switchToSpeaker
            ))
        }

        // 2. 볼륨 & 음소거 상태: 현재 상태가 무음이므로 사용자 인지가 필요한 .warning
        if audio.isMuted {
            warnings.append(PreflightWarning(
                kind: .muted,
                text: .systemMuted,
                severity: .warning,
                icon: "speaker.slash.fill",
                actionText: .unmuteToSafeVolume
            ))
        } else if audio.volume < 0.3 {
            warnings.append(PreflightWarning(
                kind: .lowVolume,
                text: .lowVolume(percent: Int(audio.volume * 100)),
                severity: .warning,
                icon: "speaker.wave.1.fill",
                actionText: .adjustToSafeVolume
            ))
        }

        // 3. 전원 깨우기 상태 (나이트스탠드 등 절전 방지 활성이거나 전원 예약이 되어 있는 경우 정상)
        if let alarm, alarm.isEnabled && !wakeScheduled && !isSleepPrevented {
            warnings.append(PreflightWarning(
                kind: .wakeNotScheduled,
                text: .wakeNotScheduled,
                severity: .warning,
                icon: "bolt.slash.fill",
                actionText: nil
            ))
        }

        // 4. 외부 앱 자동화 권한.
        //    볼륨·출력기기와 달리 AudioGuard가 발화 시점에 고쳐줄 수 없다.
        //    권한이 없으면 사용자가 고른 음악은 재생되지 않는다(백업음만 울린다).
        if !automation.canPlay, let target = automation.target {
            switch automation.status {
            case .denied:
                warnings.append(PreflightWarning(
                    kind: .automationDenied,
                    text: .automationDenied(target: target),
                    severity: .warning,
                    icon: "lock.slash.fill",
                    actionText: .openSettings
                ))
            case .notDetermined:
                warnings.append(PreflightWarning(
                    kind: .automationDenied,
                    text: .automationNotDetermined(target: target),
                    severity: .warning,
                    icon: "lock.open.fill",
                    actionText: .requestPermission
                ))
            case .appNotInstalled:
                warnings.append(PreflightWarning(
                    kind: .automationDenied,
                    text: .automationNotInstalled(target: target),
                    severity: .warning,
                    icon: "questionmark.app.fill",
                    actionText: nil
                ))
            case .notRequired, .granted, .unknown:
                break
            }
        }

        // 5. 앱이 로그인 시 자동 실행되는가.
        //    앱이 떠 있지 않으면 알람은 울리지 않는다. 볼륨이나 출력기기와 달리
        //    발화 시점에 앱이 스스로 고칠 수 없는 유일한 항목이다.
        if let alarm, alarm.isEnabled && !launchesAtLogin {
            warnings.append(PreflightWarning(
                kind: .notLaunchAtLogin,
                text: .notLaunchAtLoginWarning,
                severity: .warning,
                icon: "power",
                actionText: .enableLaunchAtLogin
            ))
        }

        let isSafe = warnings.filter({ $0.severity == .warning }).isEmpty
        let summaryTexts: [LocalizedText]
        if isSafe {
            summaryTexts = [.allReady, .builtInSpeakerProtected, .wakeScheduled]
        } else {
            summaryTexts = warnings.map(\.text)
        }

        return PreflightReport(isSafe: isSafe, warnings: warnings, summaryTexts: summaryTexts, audio: audio)
    }
}
