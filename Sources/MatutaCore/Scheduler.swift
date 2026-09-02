import Foundation

/// 알람 목록에서 다음에 울릴 하나를 골라 타이머를 건다.
@MainActor
public final class Scheduler {
    private let clock: WallClock
    private let calendar: Calendar
    private let timer: AlarmTimer
    private let onFire: (Alarm) -> Void

    public private(set) var nextFire: (alarm: Alarm, date: Date)?

    public init(
        clock: WallClock,
        calendar: Calendar,
        timer: AlarmTimer,
        onFire: @escaping (Alarm) -> Void
    ) {
        self.clock = clock
        self.calendar = calendar
        self.timer = timer
        self.onFire = onFire
    }

    /// 알람이 추가·수정·삭제되거나, 앱이 시작하거나, 절전에서 깨어날 때 호출한다.
    public func update(alarms: [Alarm]) {
        let candidates = alarms.compactMap { alarm -> (alarm: Alarm, date: Date)? in
            guard let date = NextOccurrence.next(
                for: alarm, after: clock.now, calendar: calendar
            ) else { return nil }
            return (alarm, date)
        }

        guard let earliest = candidates.min(by: { $0.date < $1.date }) else {
            nextFire = nil
            timer.cancel()
            return
        }

        nextFire = earliest
        timer.schedule(at: earliest.date) { [weak self] in
            guard let self else { return }
            self.onFire(earliest.alarm)
        }
    }
}
