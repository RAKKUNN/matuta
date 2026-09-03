import Testing
import Foundation
@testable import MatutaCore

@Test("시간 증감: 12에서 증가하면 1이고 1에서 감소하면 12로 순환한다")
func testStepHourWrapAround() {
    #expect(TimePickerLogic.stepHour(12, delta: 1) == 1)
    #expect(TimePickerLogic.stepHour(1, delta: -1) == 12)
    #expect(TimePickerLogic.stepHour(7, delta: 1) == 8)
    #expect(TimePickerLogic.stepHour(7, delta: -1) == 6)
}

@Test("분 증감: 59에서 증가하면 0이고 0에서 감소하면 59로 순환한다")
func testStepMinuteWrapAround() {
    #expect(TimePickerLogic.stepMinute(59, delta: 1) == 0)
    #expect(TimePickerLogic.stepMinute(0, delta: -1) == 59)
    #expect(TimePickerLogic.stepMinute(30, delta: 1) == 31)
    #expect(TimePickerLogic.stepMinute(30, delta: -1) == 29)
}

@Test("시 텍스트 입력 파싱: 단자리 2~9 입력 시 즉시 분으로 자동 전진한다")
func testParseHourInputAdvance() {
    let res8 = TimePickerLogic.parseHourInput("8")
    #expect(res8?.value == 8)
    #expect(res8?.shouldAdvance == true)

    let res1 = TimePickerLogic.parseHourInput("1")
    #expect(res1?.value == 1)
    #expect(res1?.shouldAdvance == false)

    let res12 = TimePickerLogic.parseHourInput("12")
    #expect(res12?.value == 12)
    #expect(res12?.shouldAdvance == true)

    let res07 = TimePickerLogic.parseHourInput("07")
    #expect(res07?.value == 7)
    #expect(res07?.shouldAdvance == true)

    let resOver = TimePickerLogic.parseHourInput("99")
    #expect(resOver?.value == 12)
    #expect(resOver?.shouldAdvance == true)
}

@Test("분 텍스트 입력 파싱: 2자리 입력 시 완료 판정한다")
func testParseMinuteInput() {
    let res5 = TimePickerLogic.parseMinuteInput("5")
    #expect(res5?.value == 5)
    #expect(res5?.shouldAdvance == false)

    let res45 = TimePickerLogic.parseMinuteInput("45")
    #expect(res45?.value == 45)
    #expect(res45?.shouldAdvance == true)

    let resOver = TimePickerLogic.parseMinuteInput("80")
    #expect(resOver?.value == 59)
    #expect(resOver?.shouldAdvance == true)
}

@Test("TimeInputBuffer: 시(Hour) 입력 시 2~9는 즉시 확정 전진하고, 1은 두 번째 자리까지 대기한다")
func testTimeInputBufferHour() {
    var buffer = TimeInputBuffer()
    let now = Date()

    // '8' -> 8, advance = true
    let res8 = buffer.appendHourDigit("8", currentHour: 7, now: now)
    #expect(res8.newHour == 8)
    #expect(res8.advance == true)

    // '1' -> 1, advance = false; '2' -> 12, advance = true
    let res1 = buffer.appendHourDigit("1", currentHour: 8, now: now)
    #expect(res1.newHour == 1)
    #expect(res1.advance == false)
    let res12 = buffer.appendHourDigit("2", currentHour: 1, now: now)
    #expect(res12.newHour == 12)
    #expect(res12.advance == true)
}

@Test("TimeInputBuffer: 분(Minute) 입력 시 십의 자리와 일의 자리를 조합하여 2자리 완성 시 전진한다")
func testTimeInputBufferMinute() {
    var buffer = TimeInputBuffer()
    let now = Date()

    // '3' -> 30, advance = false; '5' -> 35, advance = true
    let res3 = buffer.appendMinuteDigit("3", currentMinute: 0, now: now)
    #expect(res3.newMinute == 30)
    #expect(res3.advance == false)
    let res35 = buffer.appendMinuteDigit("5", currentMinute: 30, now: now)
    #expect(res35.newMinute == 35)
    #expect(res35.advance == true)
}

