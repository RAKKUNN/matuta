import Foundation

/// 시/분 입력 버퍼, 파싱, 증감 및 자동 포커스 이동을 다루는 순수 로직
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

/// 키보드 연속 입력 처리를 위한 버퍼 (커서 없이 직관적인 타임피스 입력 제공)
public struct TimeInputBuffer: Sendable {
    private var buffer: String = ""
    private var lastInputTime: Date = .distantPast

    public init() {}

    public mutating func reset() {
        buffer = ""
        lastInputTime = .distantPast
    }

    /// '시' 자릿수 입력 처리
    public mutating func appendHourDigit(_ char: Character, currentHour: Int, now: Date = Date()) -> (newHour: Int, advance: Bool) {
        guard char.isNumber else { return (currentHour, false) }

        // 1.5초 이상 지나면 새 입력으로 간주
        if now.timeIntervalSince(lastInputTime) > 1.5 {
            buffer = ""
        }
        lastInputTime = now

        buffer.append(char)
        if buffer.count == 1 {
            let digit = Int(String(char)) ?? currentHour
            if digit >= 2 && digit <= 9 {
                // 2~9는 12시간제에서 두 자릿수가 될 수 없으므로 즉시 확정 후 분으로 전진
                buffer = ""
                return (digit, true)
            } else if digit == 0 {
                // '0' 입력 시 두 번째 자릿수(예: 07) 대기
                return (currentHour, false)
            } else {
                // '1' 입력 시 1, 10, 11, 12 가능. 우선 1로 표기 후 두 번째 자릿수 대기
                return (1, false)
            }
        } else {
            // 두 번째 자릿수
            let val = Int(buffer) ?? currentHour
            buffer = ""
            if val >= 1 && val <= 12 {
                return (val, true)
            } else if val == 0 {
                return (12, true)
            } else {
                let second = Int(String(char)) ?? currentHour
                return (min(max(second, 1), 12), true)
            }
        }
    }

    /// '분' 자릿수 입력 처리
    public mutating func appendMinuteDigit(_ char: Character, currentMinute: Int, now: Date = Date()) -> (newMinute: Int, advance: Bool) {
        guard char.isNumber else { return (currentMinute, false) }

        if now.timeIntervalSince(lastInputTime) > 1.5 {
            buffer = ""
        }
        lastInputTime = now

        buffer.append(char)
        if buffer.count == 1 {
            let digit = Int(String(char)) ?? 0
            if digit >= 6 {
                // 분은 60 이상이 없으므로 06~09로 즉시 확정
                buffer = ""
                return (digit, true)
            } else {
                // 0~5: 십의 자리로 임시 표기 후 일의 자리 대기
                return (digit * 10, false)
            }
        } else {
            // 두 번째 자릿수 완료
            let val = Int(buffer) ?? currentMinute
            buffer = ""
            return (min(max(val, 0), 59), true)
        }
    }
}
