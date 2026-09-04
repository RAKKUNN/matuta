import Foundation

/// 자동화 대상 외부 애플리케이션
public enum AutomationTarget: String, Sendable, Equatable, CaseIterable {
    case spotify
    case appleMusic
}

/// 외부 앱(Spotify, 음악) 자동화 권한 상태를 나타내는 불변 값 타입.
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
        case unknown
        /// 대상 앱이 설치되어 있지 않다
        case appNotInstalled
    }

    /// 자동화 대상 앱 (nil이면 자동화가 필요 없는 소스)
    public let target: AutomationTarget?
    public let status: Status

    public init(target: AutomationTarget?, status: Status) {
        self.target = target
        self.status = status
    }

    public static let notRequired = AutomationSnapshot(
        target: nil, status: .notRequired
    )

    /// 알람 시각에 선택한 음악이 실제로 재생될 수 있는 상태인가.
    public var canPlay: Bool {
        switch status {
        case .notRequired, .granted, .unknown: true
        case .denied, .notDetermined, .appNotInstalled: false
        }
    }
}
