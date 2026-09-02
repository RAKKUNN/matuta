import Testing
import Foundation
@testable import MatutaCore

/// 테스트는 절대 실제 시계나 실행 머신의 시간대에 의존하지 않는다.
private let seoul = TimeZone(identifier: "Asia/Seoul")!

private func makeCalendar(_ tz: TimeZone = seoul) -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    return cal
}

private func date(
    _ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int,
    _ tz: TimeZone = seoul
) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    return cal.date(from: DateComponents(
        year: y, month: mo, day: d, hour: h, minute: mi, second: 0
    ))!
}

@Test("반복 없는 알람: 오늘 시각이 아직 안 지났으면 오늘이다")
func oneShotLaterToday() {
    // 2026-09-02는 수요일
    let alarm = Alarm(hour: 7, minute: 0)
    let now = date(2026, 9, 2, 6, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    #expect(next == date(2026, 9, 2, 7, 0))
}

@Test("반복 없는 알람: 오늘 시각이 지났으면 내일이다")
func oneShotTomorrow() {
    let alarm = Alarm(hour: 7, minute: 0)
    let now = date(2026, 9, 2, 8, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    #expect(next == date(2026, 9, 3, 7, 0))
}

@Test("정확히 알람 시각일 때는 다음 날로 넘어간다")
func exactlyAtAlarmTimeMovesOn() {
    let alarm = Alarm(hour: 7, minute: 0)
    let now = date(2026, 9, 2, 7, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    #expect(next == date(2026, 9, 3, 7, 0))
}

@Test("평일 반복: 금요일 저녁이면 다음은 월요일이다")
func weekdayRepeatSkipsWeekend() {
    let alarm = Alarm(
        hour: 7, minute: 0,
        weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]
    )
    // 2026-09-04는 금요일
    let now = date(2026, 9, 4, 20, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    // 2026-09-07이 월요일
    #expect(next == date(2026, 9, 7, 7, 0))
}

@Test("여러 요일이 걸려 있으면 그중 가장 이른 날을 고른다")
func picksEarliestMatchingWeekday() {
    let alarm = Alarm(hour: 7, minute: 0, weekdays: [.monday, .thursday])
    // 2026-09-02 수요일 저녁 → 목요일이 월요일보다 이르다
    let now = date(2026, 9, 2, 20, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    #expect(next == date(2026, 9, 3, 7, 0))
}

@Test("꺼져 있는 알람은 다음 발생 시각이 없다")
func disabledAlarmHasNoNext() {
    var alarm = Alarm(hour: 7, minute: 0)
    alarm.isEnabled = false
    let now = date(2026, 9, 2, 6, 0)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar())

    #expect(next == nil)
}

@Test("서머타임으로 건너뛴 시각이어도 nil을 내지 않는다")
func survivesDaylightSavingGap() {
    // 뉴욕은 2026-03-08 02:00에 03:00으로 건너뛴다. 02:30은 존재하지 않는다.
    let newYork = TimeZone(identifier: "America/New_York")!
    let alarm = Alarm(hour: 2, minute: 30)
    let now = date(2026, 3, 8, 1, 0, newYork)

    let next = NextOccurrence.next(for: alarm, after: now, calendar: makeCalendar(newYork))

    // 존재하지 않는 시각이므로 그 다음 유효한 시각으로 밀린다.
    // 정확히 언제인지보다 "nil이 아니고 현재보다 미래"라는 점이 중요하다.
    #expect(next != nil)
    #expect(next! > now)
}
