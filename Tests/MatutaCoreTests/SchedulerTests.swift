import Testing
import Foundation
@testable import MatutaCore

private let seoul = TimeZone(identifier: "Asia/Seoul")!

private func testCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = seoul
    return cal
}

private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = seoul
    return cal.date(from: DateComponents(
        year: y, month: mo, day: d, hour: h, minute: mi, second: 0
    ))!
}

private struct FixedClock: WallClock {
    let now: Date
}

@MainActor
private final class FakeTimer: AlarmTimer {
    var scheduledDate: Date?
    var cancelCount = 0
    private var handler: (@MainActor () -> Void)?

    func schedule(at date: Date, handler: @escaping @MainActor () -> Void) {
        scheduledDate = date
        self.handler = handler
    }

    func cancel() {
        cancelCount += 1
        scheduledDate = nil
        handler = nil
    }

    /// 테스트가 시간이 흐른 척한다.
    func triggerNow() {
        handler?()
    }
}

@MainActor
@Test("가장 이른 알람에 타이머를 건다")
func schedulesEarliestAlarm() {
    let timer = FakeTimer()
    let scheduler = Scheduler(
        clock: FixedClock(now: date(2026, 9, 2, 6, 0)),
        calendar: testCalendar(),
        timer: timer,
        onFire: { _ in }
    )

    scheduler.update(alarms: [
        Alarm(hour: 9, minute: 0),
        Alarm(hour: 7, minute: 0),
    ])

    #expect(timer.scheduledDate == date(2026, 9, 2, 7, 0))
    #expect(scheduler.nextFire?.alarm.hour == 7)
}

@MainActor
@Test("꺼진 알람은 무시한다")
func ignoresDisabledAlarms() {
    let timer = FakeTimer()
    let scheduler = Scheduler(
        clock: FixedClock(now: date(2026, 9, 2, 6, 0)),
        calendar: testCalendar(),
        timer: timer,
        onFire: { _ in }
    )

    scheduler.update(alarms: [
        Alarm(hour: 7, minute: 0, isEnabled: false),
        Alarm(hour: 9, minute: 0),
    ])

    #expect(timer.scheduledDate == date(2026, 9, 2, 9, 0))
}

@MainActor
@Test("켜진 알람이 하나도 없으면 타이머를 끈다")
func cancelsWhenNothingEnabled() {
    let timer = FakeTimer()
    let scheduler = Scheduler(
        clock: FixedClock(now: date(2026, 9, 2, 6, 0)),
        calendar: testCalendar(),
        timer: timer,
        onFire: { _ in }
    )

    scheduler.update(alarms: [Alarm(hour: 7, minute: 0, isEnabled: false)])

    #expect(timer.scheduledDate == nil)
    #expect(scheduler.nextFire == nil)
}

@MainActor
@Test("시각이 되면 그 알람을 넘겨준다")
func firesWithTheCorrectAlarm() {
    let timer = FakeTimer()
    var fired: [Alarm] = []
    let scheduler = Scheduler(
        clock: FixedClock(now: date(2026, 9, 2, 6, 0)),
        calendar: testCalendar(),
        timer: timer,
        onFire: { fired.append($0) }
    )

    let target = Alarm(hour: 7, minute: 0, label: "기상")
    scheduler.update(alarms: [target, Alarm(hour: 9, minute: 0)])
    timer.triggerNow()

    #expect(fired.count == 1)
    #expect(fired.first?.id == target.id)
}
