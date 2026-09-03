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
