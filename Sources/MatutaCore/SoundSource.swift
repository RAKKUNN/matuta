import Foundation

/// 소스 플러그인 공통 프로토콜.
///
/// 설계 문서 §8.2:
/// `SoundSource`가 이 설계의 중심이다. 소스를 6개 지원하는 것이 아니라 인터페이스 하나를 6번 구현한다.
/// `PlaybackChain`과 `Preflight`는 소스의 구체 타입을 전혀 모른다.
@MainActor
public protocol SoundSource: AnyObject {
    var sourceRef: SoundSourceRef { get }
    var displayName: String { get }
    var requiresNetwork: Bool { get }
    /// 재생 성공 여부를 앱 내부에서 검증할 수 없는 소스 (Spotify, 일반 웹 등)
    var needsBackupTone: Bool { get }

    func preflight() async -> PreflightResult
    func play(volume: Double, fadeIn: Bool) async throws
    func stop()
}
