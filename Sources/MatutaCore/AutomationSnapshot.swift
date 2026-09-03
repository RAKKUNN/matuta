import Foundation

/// 외부 앱(Spotify, 음악) 자동화 권한 상태를 나타내는 불변 값 타입.
///
/// `AudioSnapshot`과 같은 역할이다 — 앱 레이어가 시스템에서 읽어오고,
/// 판정은 `PreflightEvaluator`가 한다.
///
/// 이 상태가 중요한 이유: Spotify·Apple Music 알람은 AppleScript로 외부 앱을
/// 제어하는데, 자동화 권한이 없으면 알람 시각에 조용히 실패한다. `AudioGuard`가
/// 울릴 때 고쳐줄 수 있는 볼륨·출력기기와 달리 **발화 시점에는 손쓸 수 없다.**
/// 그래서 자기 전에 미리 알려야 한다.
public struct AutomationSnapshot: Sendable, Equatable {
    public enum Status: Sendable, Equatable {
        /// 선택된 소스가 외부 앱 제어를 쓰지 않는다 (내장음, 로컬 파일 등)
        case notRequired
        /// 권한이 허용되어 있다
        case granted
        /// 사용자가 거부했다. 시스템 설정에서 직접 켜야 한다
        case denied
        /// 아직 물어본 적이 없다. 요청하면 대화상자가 뜬다
        case notDetermined
        /// 판별할 수 없다.
        ///
        /// 실측 결과(2026-09-03): `AEDeterminePermissionToAutomateTarget`은 대상 앱이
        /// **실행 중이 아니면 실제 권한 상태와 무관하게 -600(procNotFound)** 을 반환한다.
        /// 잠들기 전에는 Spotify·음악 앱이 꺼져 있는 것이 정상이므로, 이 상태를 문제로
        /// 취급하면 매일 밤 헛경고가 뜬다. 그래서 경고하지 않는다.
        case unknown
        /// 대상 앱이 설치되어 있지 않다
        case appNotInstalled
    }

    /// 사용자에게 보여줄 대상 앱 이름 ("Spotify", "음악")
    public let targetName: String
    public let status: Status

    public init(targetName: String, status: Status) {
        self.targetName = targetName
        self.status = status
    }

    public static let notRequired = AutomationSnapshot(
        targetName: "", status: .notRequired
    )

    /// 알람 시각에 선택한 음악이 실제로 재생될 수 있는 상태인가.
    public var canPlay: Bool {
        switch status {
        case .notRequired, .granted, .unknown: true
        case .denied, .notDetermined, .appNotInstalled: false
        }
    }
}
