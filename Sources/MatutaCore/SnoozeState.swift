import Foundation

/// 활성화된 스누즈 상태를 나타내는 불변 값 타입.
///
/// 설계 문서 §7.2 & 진단서 2.C:
/// - 스누즈 시각과 대상 알람 ID를 캡슐화하여, 디스크 영속화 및 절전 깨우기 계산에 직접 전달한다.
public struct SnoozeState: Codable, Equatable, Sendable {
    public let alarmID: UUID
    public let fireAt: Date

    public init(alarmID: UUID, fireAt: Date) {
        self.alarmID = alarmID
        self.fireAt = fireAt
    }

    /// 스누즈 유효성 검사 (과거 시각인지 여부)
    public func isValid(at now: Date) -> Bool {
        fireAt > now
    }
}
