import Foundation

extension Localizer {
    static func stringForPreflight(_ text: LocalizedText, _ language: ResolvedLanguage) -> String {
        switch text {
        case .headphonesConnected:
            switch language {
            case .korean: return "이어폰 연결됨 (울릴 때 내장 스피커로 자동 전환)"
            case .english: return "Headphones connected (Switches to speaker on alarm)"
            }

        case .switchToSpeaker:
            switch language {
            case .korean: return "스피커로 전환"
            case .english: return "Switch to Speaker"
            }

        case .builtInSpeakerReady:
            switch language {
            case .korean: return "내장 스피커 준비됨"
            case .english: return "Built-in Speaker Ready"
            }

        case .systemMuted:
            switch language {
            case .korean: return "시스템이 음소거 상태입니다 (울릴 때 자동 해제)"
            case .english: return "System is muted (Automatically unmuted on alarm)"
            }

        case .unmuteToSafeVolume:
            switch language {
            case .korean: return "70%로 해제"
            case .english: return "Unmute to 70%"
            }

        case .lowVolume(let percent):
            switch language {
            case .korean: return "현재 볼륨이 낮습니다 (\(percent)%)"
            case .english: return "Volume is low (\(percent)%)"
            }

        case .adjustToSafeVolume:
            switch language {
            case .korean: return "70%로 조정"
            case .english: return "Adjust to 70%"
            }

        case .wakeNotScheduled:
            switch language {
            case .korean: return "전원 자동 깨우기가 예약되지 않았습니다"
            case .english: return "Auto-wake is not scheduled"
            }

        case .automationDenied(let target):
            let name = stringForAppName(target, language)
            switch language {
            case .korean: return "\(name) 제어 권한이 꺼져 있습니다 (백업음만 울립니다)"
            case .english: return "\(name) control permission is denied (Backup tone only)"
            }

        case .openSettings:
            switch language {
            case .korean: return "설정 열기"
            case .english: return "Open Settings"
            }

        case .automationNotDetermined(let target):
            let name = stringForAppName(target, language)
            switch language {
            case .korean: return "\(name) 제어 권한이 아직 허용되지 않았습니다"
            case .english: return "\(name) control permission not yet granted"
            }

        case .requestPermission:
            switch language {
            case .korean: return "권한 허용"
            case .english: return "Grant Permission"
            }

        case .automationNotInstalled(let target):
            let name = stringForAppName(target, language)
            switch language {
            case .korean: return "\(name) 앱이 설치되어 있지 않습니다 (백업음만 울립니다)"
            case .english: return "\(name) is not installed (Backup tone only)"
            }

        case .speakerProtectionReady:
            switch language {
            case .korean: return "울릴 때 스피커 보호 전환"
            case .english: return "Speaker protected on alarm"
            }

        case .sleepPreventionActive:
            switch language {
            case .korean: return "절전 방지 활성"
            case .english: return "Sleep Prevention Active"
            }

        case .allReady:
            switch language {
            case .korean: return "모든 준비 완료"
            case .english: return "All Ready"
            }

        case .builtInSpeakerProtected:
            switch language {
            case .korean: return "내장 스피커 보호"
            case .english: return "Built-in Speaker Protected"
            }

        case .wakeScheduled:
            switch language {
            case .korean: return "절전 깨우기 예약됨"
            case .english: return "Power Wake Scheduled"
            }

        default:
            return ""
        }
    }
}
