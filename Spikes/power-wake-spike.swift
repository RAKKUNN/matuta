// Spikes/power-wake-spike.swift
// 실행: swift Spikes/power-wake-spike.swift
import Foundation
import IOKit
import IOKit.pwr_mgt

let wakeAt = Date().addingTimeInterval(120)

let result = IOPMSchedulePowerEvent(
    wakeAt as CFDate,
    "com.matuta.spike" as CFString,
    kIOPMAutoWakeOrPowerOn as CFString
)

if result == kIOReturnSuccess {
    print("성공: 권한 없이 전원 이벤트 예약됨 (\(wakeAt))")
} else {
    print("실패: IOReturn=\(String(format: "0x%08X", result))")
    if result == kIOReturnNotPrivileged {
        print("→ kIOReturnNotPrivileged: 관리자 권한이 필요함")
    }
}
