import Foundation

/// 시/분 입력 파싱, 증감 및 자동 포커스 이동을 다루는 순수 로직
public struct TimePickerLogic: Sendable {
    /// 12시간제 시(1...12) 증감 (순환 랩어라운드 지원)
    public static func stepHour(_ current: Int, delta: Int) -> Int {
        var next = current + delta
        while next > 12 { next -= 12 }
        while next < 1 { next += 12 }
        return next
    }

    /// 분(0...59) 증감 (순환 랩어라운드 지원)
    public static func stepMinute(_ current: Int, delta: Int) -> Int {
        var next = (current + delta) % 60
        if next < 0 { next += 60 }
        return next
    }

    public struct ParseResult: Sendable, Equatable {
        public let value: Int
        public let shouldAdvance: Bool

        public init(value: Int, shouldAdvance: Bool) {
            self.value = value
            self.shouldAdvance = shouldAdvance
        }
    }

    /// 사용자가 시(Hour) 텍스트를 입력했을 때 파싱 및 분(Minute) 자동 이동 판단
    public static func parseHourInput(_ text: String) -> ParseResult? {
        let digits = text.filter { $0.isNumber }
        guard let num = Int(digits), num > 0 else { return nil }
        if num > 12 {
            return ParseResult(value: 12, shouldAdvance: true)
        }
        // 12시간제에서 2~9로 시작하면 12 이하인 두 자릿수가 될 수 없으므로 즉시 분으로 자동 전진
        let shouldAdvance = (num >= 2 && num <= 9) || digits.count >= 2
        return ParseResult(value: num, shouldAdvance: shouldAdvance)
    }

    /// 사용자가 분(Minute) 텍스트를 입력했을 때 파싱
    public static func parseMinuteInput(_ text: String) -> ParseResult? {
        let digits = text.filter { $0.isNumber }
        guard let num = Int(digits) else { return nil }
        if num > 59 {
            return ParseResult(value: 59, shouldAdvance: true)
        }
        let shouldAdvance = digits.count >= 2
        return ParseResult(value: num, shouldAdvance: shouldAdvance)
    }

    /// 두 자릿수("07", "00") 포맷
    public static func formatTwoDigits(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}
