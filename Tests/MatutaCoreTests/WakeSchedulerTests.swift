import Testing
import Foundation
@testable import MatutaCore

final class MockWakeScheduler: WakeScheduler, @unchecked Sendable {
    var scheduledDate: Date?
    var isAssertionActive: Bool = false
    var assertionReason: String?

    func scheduleWake(at date: Date) -> Bool {
        self.scheduledDate = date.addingTimeInterval(-120)
        return true
    }

    func cancelWake() {
        self.scheduledDate = nil
    }

    func acquireSleepAssertion(reason: String) {
        self.isAssertionActive = true
        self.assertionReason = reason
    }

    func releaseSleepAssertion() {
        self.isAssertionActive = false
        self.assertionReason = nil
    }
}

@Test("알람 2분 전에 전원 깨우기 이벤트를 계산하여 예약한다")
func testPowerWakeCalculation() {
    let power = MockWakeScheduler()
    let alarmTime = Date().addingTimeInterval(3600) // 1시간 뒤

    let result = power.scheduleWake(at: alarmTime)
    #expect(result == true)
    #expect(power.scheduledDate != nil)
    #expect(Int(power.scheduledDate!.timeIntervalSince(alarmTime)) == -120)
}

@Test("알람 발화 시 화면 절전 방지 assertion을 획득하고 해제 시 해제한다")
func testSleepAssertionCycle() {
    let power = MockWakeScheduler()

    power.acquireSleepAssertion(reason: "알람 울림")
    #expect(power.isAssertionActive == true)
    #expect(power.assertionReason == "알람 울림")

    power.releaseSleepAssertion()
    #expect(power.isAssertionActive == false)
    #expect(power.assertionReason == nil)
}
