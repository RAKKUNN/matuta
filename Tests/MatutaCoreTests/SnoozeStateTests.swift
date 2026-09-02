import Testing
import Foundation
@testable import MatutaCore

@Test("스누즈 상태가 JSON으로 인코딩/디코딩되어 정상 복원된다")
func testSnoozeStateCodable() throws {
    let id = UUID()
    let fireAt = Date().addingTimeInterval(540) // 9분 후
    let snooze = SnoozeState(alarmID: id, fireAt: fireAt)

    let data = try JSONEncoder().encode(snooze)
    let decoded = try JSONDecoder().decode(SnoozeState.self, from: data)

    #expect(decoded.alarmID == id)
    #expect(abs(decoded.fireAt.timeIntervalSince(fireAt)) < 0.001)
}

@Test("스누즈가 걸려 있으면 스케줄러의 다음 발화 시각이 스누즈 시각으로 우선 반영된다")
@MainActor
func testSchedulerPrioritizesSnooze() {
    let clock = SystemClock()
    let calendar = Calendar.current
    let timer = MockAlarmTimer()
    let scheduler = Scheduler(clock: clock, calendar: calendar, timer: timer, onFire: { _ in })

    let alarm1 = Alarm(hour: 8, minute: 0, weekdays: [.monday], isEnabled: true)
    let snoozeTime = Date().addingTimeInterval(540) // 9분 뒤
    let snooze = SnoozeState(alarmID: alarm1.id, fireAt: snoozeTime)

    scheduler.update(alarms: [alarm1], snooze: snooze)

    #expect(scheduler.nextFire != nil)
    #expect(scheduler.nextFire?.alarm.id == alarm1.id)
    #expect(scheduler.nextFire?.date == snoozeTime)
}

@Test("AlarmStore가 알람과 스누즈 페이로드를 함께 저장하고 복원한다")
func testAlarmStorePayloadSaveAndLoad() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let fileURL = tempDir.appendingPathComponent("alarms.json")
    let store = AlarmStore(fileURL: fileURL)

    let alarm = Alarm(hour: 6, minute: 45, isEnabled: true)
    let snooze = SnoozeState(alarmID: alarm.id, fireAt: Date().addingTimeInterval(300))
    let payload = AlarmStorePayload(alarms: [alarm], snooze: snooze)

    try store.savePayload(payload)

    let loaded = store.loadPayload()
    #expect(loaded.alarms.count == 1)
    #expect(loaded.alarms[0].id == alarm.id)
    #expect(loaded.snooze?.alarmID == alarm.id)

    try? FileManager.default.removeItem(at: tempDir)
}

private final class MockAlarmTimer: AlarmTimer, @unchecked Sendable {
    var scheduledDate: Date?
    var isCancelled: Bool = false

    func schedule(at date: Date, handler: @escaping @MainActor () -> Void) {
        self.scheduledDate = date
        self.isCancelled = false
    }

    func cancel() {
        self.scheduledDate = nil
        self.isCancelled = true
    }
}
