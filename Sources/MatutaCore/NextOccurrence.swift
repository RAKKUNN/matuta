import Foundation

/// 알람의 다음 발생 시각을 계산한다. 부수 효과가 없는 순수 함수다.
public enum NextOccurrence {

    /// - Returns: `date` 이후 가장 이른 발생 시각. 알람이 꺼져 있으면 `nil`.
    public static func next(
        for alarm: Alarm,
        after date: Date,
        calendar: Calendar
    ) -> Date? {
        guard alarm.isEnabled else { return nil }

        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute
        components.second = 0

        // 반복 요일이 없으면 1회성 알람이다. 오늘 아니면 내일.
        if alarm.weekdays.isEmpty {
            return calendar.nextDate(
                after: date,
                matching: components,
                matchingPolicy: .nextTime
            )
        }

        // 요일마다 다음 발생 시각을 구해서 가장 이른 것을 고른다.
        // `.nextTime` 정책은 서머타임으로 사라진 시각을 다음 유효 시각으로 민다.
        return alarm.weekdays.compactMap { weekday -> Date? in
            var dayComponents = components
            dayComponents.weekday = weekday.rawValue
            return calendar.nextDate(
                after: date,
                matching: dayComponents,
                matchingPolicy: .nextTime
            )
        }.min()
    }
}
