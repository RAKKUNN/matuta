import Foundation

/// 현재 시각을 주입하기 위한 통로. 테스트가 실제 시계에 의존하지 않게 한다.
public protocol WallClock: Sendable {
    var now: Date { get }
}

public struct SystemClock: WallClock {
    public init() {}
    public var now: Date { Date() }
}
