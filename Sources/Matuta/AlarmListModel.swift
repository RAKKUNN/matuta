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

    /// 현재 스누즈 진행 중인 알람 정보
    var snoozingAlarmID: UUID?
    var snoozeUntil: Date?
    private var snoozeTimer: Timer?

    private let store: AlarmStore
    private var scheduler: Scheduler?
    private let tonePlayer = TonePlayer()
    public let playbackChain = PlaybackChain()
    private let overlay = AlarmOverlayController()
    private let powerManager = SystemPowerMatuta()
    private let audioGuard = AudioGuard()
    private let nightstand = NightstandController()
    public let preflightEngine = PreflightEngine()

    init(store: AlarmStore = AlarmStore(fileURL: AlarmStore.defaultFileURL)) {
        self.store = store

        let loaded = store.load()
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
        if let snooze = snoozeUntil, snooze > Date() {
            return snooze
        }
        return scheduler?.nextFire?.date
    }

    var nextAlarm: Alarm? {
        if let snoozingID = snoozingAlarmID, let alarm = alarms.first(where: { $0.id == snoozingID }) {
            return alarm
        }
        return scheduler?.nextFire?.alarm
    }

    func toggle(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
        if !alarms[index].isEnabled && snoozingAlarmID == alarm.id {
            cancelSnooze()
        }
        persist()
    }

    func addAlarm() {
        editing = Alarm(hour: 7, minute: 0, source: .builtIn(name: "Morning Harp"))
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
        if snoozingAlarmID == alarm.id {
            cancelSnooze()
        }
        alarms.removeAll { $0.id == alarm.id }
        persist()
    }

    /// 나이트스탠드(전체화면 침대 시계 모드) 열기
    func openNightstand() {
        nightstand.show(nextFireDate: nextFireDate, nextAlarm: nextAlarm)
    }

    /// 스페이스바 또는 마우스 클릭으로 알람을 완전히 껐을 때.
    func dismissFiring() {
        playbackChain.stop()
        audioGuard.restore()
        powerManager.releaseSleepAssertion()
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
        playbackChain.stop()
        audioGuard.restore()
        powerManager.releaseSleepAssertion()
        overlay.hide()
        firing = nil

        let snoozeAt = Date().addingTimeInterval(Double(minutes) * 60)
        self.snoozingAlarmID = alarm.id
        self.snoozeUntil = snoozeAt

        snoozeTimer?.invalidate()
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: snoozeAt.timeIntervalSinceNow, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.snoozingAlarmID = nil
                self?.snoozeUntil = nil
                self?.fire(alarm)
            }
        }
    }

    func cancelSnooze() {
        snoozeTimer?.invalidate()
        snoozeTimer = nil
        snoozingAlarmID = nil
        snoozeUntil = nil
    }

    private func fire(_ alarm: Alarm) {
        firing = alarm
        snoozingAlarmID = nil
        snoozeUntil = nil

        // 1. 화면/시스템 절전 방지 활성화
        powerManager.acquireSleepAssertion(reason: "Matuta Alarm Firing")

        // 2. AudioGuard: 내장 스피커 강제 라우팅, 뮤트 해제, 볼륨 확보
        audioGuard.protect(targetVolume: Float(alarm.volume))

        // 3. 사운드 재생 체인 시작
        let primary = SoundSourceFactory.makeSource(for: alarm.source, tonePlayer: tonePlayer)
        let backup = SoundSourceFactory.backupSource(tonePlayer: tonePlayer)

        Task { @MainActor in
            await playbackChain.start(
                primary: primary,
                backup: backup,
                volume: alarm.volume,
                fadeIn: alarm.fadeIn
            )
        }

        // 4. 전체화면 오버레이 표시
        overlay.show(
            alarm: alarm,
            playbackChain: playbackChain,
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

        // 다음 알람 2분 전 Mac 절전 깨우기 자동 예약
        if let next = scheduler?.nextFire?.date {
            powerManager.scheduleWake(at: next)
        } else {
            powerManager.cancelWake()
        }
    }
}
