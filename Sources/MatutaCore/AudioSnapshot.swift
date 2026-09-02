import Foundation

/// 시스템 오디오 기기 및 출력 상태를 나타내는 불변 값 타입.
///
/// 설계 문서 §6.1 & 진단서 2.D:
/// `AudioGuard`와 `Preflight`는 같은 상태를 본다. 차이는 시점뿐이다.
/// `Preflight`는 자기 전에 읽어서 알리고, `AudioGuard`는 울릴 때 읽어서 고친다.
/// 판정 로직은 공유한다.
public struct AudioSnapshot: Sendable, Equatable {
    public let defaultDeviceName: String
    public let isHeadphones: Bool
    public let volume: Float
    public let isMuted: Bool

    public init(
        defaultDeviceName: String,
        isHeadphones: Bool,
        volume: Float,
        isMuted: Bool
    ) {
        self.defaultDeviceName = defaultDeviceName
        self.isHeadphones = isHeadphones
        self.volume = volume
        self.isMuted = isMuted
    }
}
