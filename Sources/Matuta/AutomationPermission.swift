import AppKit
import ApplicationServices
import Foundation
import MatutaCore

/// 외부 앱 자동화(Apple Events) 권한을 시스템에서 읽어오는 I/O 어댑터.
///
/// `AudioGuard`가 `AudioSnapshot`을 만드는 것과 같은 역할이다. 판정은 하지 않고
/// 사실만 읽는다. 판정은 `PreflightEvaluator`가 한다.
///
/// **실측으로 확인한 제약(2026-09-03):**
/// `AEDeterminePermissionToAutomateTarget`은 대상 앱이 실행 중이 아니면 실제 권한과
/// 무관하게 `-600(procNotFound)`을 반환한다. 설치되어 있으나 꺼진 음악 앱과 아예
/// 설치되지 않은 Spotify가 똑같이 -600이었다. 따라서 **앱이 꺼져 있는 동안에는
/// 권한을 알 수 없고**, 그 경우 `.unknown`으로 보고해 경고하지 않는다.
/// 설치 여부만은 앱이 꺼져 있어도 확실히 알 수 있으므로 그것은 판정한다.
@MainActor
enum AutomationPermission {

    private static func target(for ref: SoundSourceRef) -> (bundleID: String, name: String)? {
        switch ref {
        case .spotify: ("com.spotify.client", "Spotify")
        case .appleMusic: ("com.apple.Music", "음악")
        case .builtIn, .localFile, .streamURL, .web: nil
        }
    }

    /// 선택된 소스에 대한 자동화 권한 상태를 읽는다.
    static func snapshot(for ref: SoundSourceRef) -> AutomationSnapshot {
        guard let target = target(for: ref) else {
            return .notRequired
        }

        guard NSWorkspace.shared
            .urlForApplication(withBundleIdentifier: target.bundleID) != nil
        else {
            return AutomationSnapshot(targetName: target.name, status: .appNotInstalled)
        }

        return AutomationSnapshot(
            targetName: target.name,
            status: determineStatus(bundleID: target.bundleID, askIfNeeded: false)
        )
    }

    /// 경고 뱃지를 눌렀을 때의 복구 동작.
    /// 아직 물어본 적이 없으면 권한 대화상자를 띄우고, 거부된 상태면 시스템 설정을 연다.
    static func resolve(for ref: SoundSourceRef) {
        guard let target = target(for: ref) else { return }

        switch determineStatus(bundleID: target.bundleID, askIfNeeded: true) {
        case .denied:
            openAutomationSettings()
        case .granted, .notDetermined, .unknown, .notRequired, .appNotInstalled:
            break
        }
    }

    static func openAutomationSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    private static func determineStatus(
        bundleID: String,
        askIfNeeded: Bool
    ) -> AutomationSnapshot.Status {
        var descriptor = AEAddressDesc()
        var created: OSErr = -1
        bundleID.withCString { pointer in
            created = AECreateDesc(
                typeApplicationBundleID, pointer, strlen(pointer), &descriptor
            )
        }
        guard created == noErr else { return .unknown }
        defer { AEDisposeDesc(&descriptor) }

        let result = AEDeterminePermissionToAutomateTarget(
            &descriptor, typeWildCard, typeWildCard, askIfNeeded
        )

        switch result {
        case noErr:
            return .granted
        case OSStatus(errAEEventNotPermitted):
            return .denied
        case OSStatus(errAEEventWouldRequireUserConsent):
            return .notDetermined
        default:
            // procNotFound(-600) 포함. 대상 앱이 꺼져 있으면 알 수 없다.
            return .unknown
        }
    }
}
