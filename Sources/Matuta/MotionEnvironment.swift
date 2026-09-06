import AppKit
import MatutaCore

/// 시스템의 "동작 줄이기" 설정을 읽는 어댑터. 판정은 하지 않는다.
@MainActor
enum MotionEnvironment {
    static var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    /// 역할에 맞는 지속시간. 호출부가 매번 시스템 설정을 묻지 않게 감싼다.
    static func duration(_ role: Motion.Role) -> Double {
        Motion.duration(role, reduceMotion: reduceMotion)
    }
}
