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

    /// 목록 창과 편집 시트에 쓰는 축약 표기 키.
    public var shortNameText: LocalizedText {
        switch self {
        case .sunday: .sundayShort
        case .monday: .mondayShort
        case .tuesday: .tuesdayShort
        case .wednesday: .wednesdayShort
        case .thursday: .thursdayShort
        case .friday: .fridayShort
        case .saturday: .saturdayShort
        }
    }

    /// 목록 창과 편집 시트에 쓰는 표기 (기본값).
    public var shortName: String {
        Localizer.string(shortNameText, .korean)
    }

    /// 편집 시트에 월요일부터 표시하기 위한 순서.
    public static let displayOrder: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]
}
