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

    /// 현재 스누즈 상태 (코어 모델)
    var snoozeState: SnoozeState?
    private var snoozeTimer: Timer?
    private var fireTask: Task<Void, Never>?

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

        let payload = store.loadPayload()
        let loadedAlarms = payload.alarms
        self.alarms = loadedAlarms.isEmpty ? AlarmStore.seedAlarms : loadedAlarms

        // 스누즈 복원 (유효한 경우 복원, 1분 이내 과거면 즉시 발화)
        if let snooze = payload.snooze {
            let now = Date()
            if snooze.isValid(at: now) {
                self.snoozeState = snooze
                armSnoozeTimer(snooze)
            } else if abs(snooze.fireAt.timeIntervalSince(now)) < 60, let alarm = self.alarms.first(where: { $0.id == snooze.alarmID }) {
                // 앱 종료 중 스누즈 시각이 막 지난 경우 즉시 발화
                DispatchQueue.main.async { [weak self] in
                    self?.fire(alarm)
                }
            }
        }

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

    var nextAlarm: Alarm? {
        scheduler?.nextFire?.alarm
    }

    var snoozingAlarmID: UUID? {
        snoozeState?.alarmID
    }

    var snoozeUntil: Date? {
        snoozeState?.fireAt
    }

    func toggle(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
        if !alarms[index].isEnabled && snoozeState?.alarmID == alarm.id {
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
        if snoozeState?.alarmID == alarm.id {
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
        fireTask?.cancel()
        fireTask = nil
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
        fireTask?.cancel()
        fireTask = nil
        playbackChain.stop()
        audioGuard.restore()
        powerManager.releaseSleepAssertion()
        overlay.hide()
        firing = nil

        let snoozeAt = Date().addingTimeInterval(Double(minutes) * 60)
        let newSnooze = SnoozeState(alarmID: alarm.id, fireAt: snoozeAt)
        self.snoozeState = newSnooze
        armSnoozeTimer(newSnooze)

        persist()
    }

    func cancelSnooze() {
        snoozeTimer?.invalidate()
        snoozeTimer = nil
        snoozeState = nil
        persist()
    }

    private func armSnoozeTimer(_ snooze: SnoozeState) {
        snoozeTimer?.invalidate()
        let delay = max(0.1, snooze.fireAt.timeIntervalSinceNow)
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let snoozedID = self.snoozeState?.alarmID
                self.snoozeState = nil
                self.persist()
                if let snoozedID, let alarm = self.alarms.first(where: { $0.id == snoozedID }) {
                    self.fire(alarm)
                }
            }
        }
    }

    private func fire(_ alarm: Alarm) {
        firing = alarm
        snoozeState = nil
        snoozeTimer?.invalidate()
        snoozeTimer = nil

        // 1. 화면/시스템 절전 방지 활성화
        powerManager.acquireSleepAssertion(reason: "Matuta Alarm Firing")

        // 2. AudioGuard: 내장 스피커 강제 라우팅, 뮤트 해제, 볼륨 확보
        audioGuard.protect(targetVolume: Float(alarm.volume))

        // 3. 사운드 재생 체인 시작
        let primary = SoundSourceFactory.makeSource(for: alarm.source, tonePlayer: tonePlayer)
        let backup = SoundSourceFactory.backupSource(tonePlayer: tonePlayer)

        fireTask?.cancel()
        fireTask = Task { @MainActor in
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
        try? store.savePayload(AlarmStorePayload(alarms: alarms, snooze: snoozeState))
        reschedule()
    }

    private func reschedule() {
        scheduler?.update(alarms: alarms, snooze: snoozeState)

        // 단일 통합 nextFire 시각 기준 2분 전 절전 깨우기 예약 (스누즈 포함)
        if let next = scheduler?.nextFire?.date {
            powerManager.scheduleWake(at: next)
        } else {
            powerManager.cancelWake()
        }
    }
}
