import Foundation

/// `Calendar`의 `weekday` 성분과 같은 값을 쓴다 (일요일 = 1).
public enum Weekday: Int, Codable, CaseIterable, Sendable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    /// 목록 창과 편집 시트에 쓰는 한 글자 표기.
    public var shortName: String {
        switch self {
        case .sunday: "일"
        case .monday: "월"
        case .tuesday: "화"
        case .wednesday: "수"
        case .thursday: "목"
        case .friday: "금"
        case .saturday: "토"
        }
    }

    /// 편집 시트에 월요일부터 표시하기 위한 순서.
    public static let displayOrder: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]
}
