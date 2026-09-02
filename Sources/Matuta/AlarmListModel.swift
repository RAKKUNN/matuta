import Foundation
import Observation
import MatutaCore

@MainActor
@Observable
final class AlarmListModel {
    private(set) var alarms: [Alarm] = []

    /// 편집 시트에 띄울 알람. `nil`이면 시트가 닫혀 있다.
    var editing: Alarm?
    /// 지금 울리고 있는 알람. `nil`이면 오버레이가 안 떠 있다.
    var firing: Alarm?

    private let store: AlarmStore
    private var scheduler: Scheduler?
    private let player = TonePlayer()
    private let overlay = AlarmOverlayController()

    init(store: AlarmStore = AlarmStore(fileURL: AlarmStore.defaultFileURL)) {
        self.store = store

        let loaded = store.load()
        // 첫 실행 시 빈 화면을 보여주지 않는다 (설계 원칙).
        alarms = loaded.isEmpty ? AlarmStore.seedAlarms : loaded

        scheduler = Scheduler(
            clock: SystemClock(),
            calendar: Calendar.current,
            timer: SystemAlarmTimer(),
            onFire: { [weak self] alarm in
                self?.fire(alarm)
            }
        )
        reschedule()
    }

    var nextFireDate: Date? {
        scheduler?.nextFire?.date
    }

    func toggle(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
        persist()
    }

    func addAlarm() {
        editing = Alarm(hour: 7, minute: 0)
    }

    func save(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }
        alarms.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        persist()
    }

    func delete(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        persist()
    }

    /// 스페이스바로 알람을 완전히 껐을 때.
    func dismissFiring() {
        player.stop()
        overlay.hide()
        if let alarm = firing, alarm.weekdays.isEmpty {
            // 1회성 알람은 울리고 나면 꺼둔다.
            if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
                alarms[index].isEnabled = false
            }
        }
        firing = nil
        persist()
    }

    /// 스누즈. 마우스 클릭으로만 도달한다.
    func snoozeFiring() {
        guard let alarm = firing, let minutes = alarm.snoozeMinutes else { return }
        player.stop()
        overlay.hide()
        firing = nil

        let snoozeAt = Date().addingTimeInterval(Double(minutes) * 60)
        Timer.scheduledTimer(withTimeInterval: snoozeAt.timeIntervalSinceNow, repeats: false) { _ in
            MainActor.assumeIsolated { [weak self] in
                self?.fire(alarm)
            }
        }
    }

    private func fire(_ alarm: Alarm) {
        firing = alarm
        // 1단계에서 재생되는 소스는 .builtIn 하나뿐이다.
        // 2단계에서 PlaybackChain이 이 자리를 대체한다.
        player.start(pattern: .radar, volume: alarm.volume, fadeIn: alarm.fadeIn)
        overlay.show(
            alarm: alarm,
            onDismiss: { [weak self] in self?.dismissFiring() },
            onSnooze: { [weak self] in self?.snoozeFiring() }
        )
    }

    private func persist() {
        try? store.save(alarms)
        reschedule()
    }

    private func reschedule() {
        scheduler?.update(alarms: alarms)
    }
}
