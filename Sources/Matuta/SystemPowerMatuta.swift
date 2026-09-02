import Foundation
import IOKit
import IOKit.pwr_mgt
import MatutaCore

/// IOKit 전원 이벤트 및 절전 방지 assertion을 관리하는 구현체.
///
/// 설계 문서 §6.1 & §9:
/// - 알람 2분 전 Mac을 절전 모드에서 자동 깨움 (`IOPMSchedulePowerEvent`)
/// - 알람 발화 중 화면 및 시스템이 꺼지지 않도록 방지 (`IOPMAssertion`)
public final class SystemPowerMatuta: PowerManagement, @unchecked Sendable {
    private let appName = "com.matuta.app" as CFString
    private let wakeType = "wake" as CFString

    private var scheduledDate: Date?
    private var displayAssertionID: IOPMAssertionID = 0
    private var systemAssertionID: IOPMAssertionID = 0
    private let lock = NSLock()

    public init() {}

    @discardableResult
    public func scheduleWake(at date: Date) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // 기존 예약 취소
        cancelWakeInternal()

        // 알람 2분 전에 깨운다 (알람이 2분 이내면 알람 시각에 깨움)
        let wakeDate = date.addingTimeInterval(-120)
        let targetDate = wakeDate > Date() ? wakeDate : date
        guard targetDate > Date() else { return false }

        let cfDate = targetDate as CFDate
        let status = IOPMSchedulePowerEvent(cfDate, appName, wakeType)
        if status == kIOReturnSuccess {
            self.scheduledDate = targetDate
            return true
        }
        return false
    }

    public func cancelWake() {
        lock.lock()
        defer { lock.unlock() }
        cancelWakeInternal()
    }

    private func cancelWakeInternal() {
        guard let scheduled = scheduledDate else { return }
        _ = IOPMCancelScheduledPowerEvent(scheduled as CFDate, appName, wakeType)
        self.scheduledDate = nil
    }

    public func acquireSleepAssertion(reason: String) {
        lock.lock()
        defer { lock.unlock() }

        // 1. 디스플레이 꺼짐 방지
        if displayAssertionID == 0 {
            _ = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason as CFString,
                &displayAssertionID
            )
        }

        // 2. 시스템 절전 방지
        if systemAssertionID == 0 {
            _ = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason as CFString,
                &systemAssertionID
            )
        }
    }

    public func releaseSleepAssertion() {
        lock.lock()
        defer { lock.unlock() }

        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }
        if systemAssertionID != 0 {
            IOPMAssertionRelease(systemAssertionID)
            systemAssertionID = 0
        }
    }

    deinit {
        cancelWake()
        releaseSleepAssertion()
    }
}
