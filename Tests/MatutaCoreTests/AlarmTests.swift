import Testing
import Foundation
@testable import MatutaCore

@Test("기본값으로 알람을 만들면 평일 반복 없이 켜져 있다")
func alarmDefaults() {
    let alarm = Alarm(hour: 7, minute: 0)

    #expect(alarm.hour == 7)
    #expect(alarm.minute == 0)
    #expect(alarm.weekdays.isEmpty)
    #expect(alarm.source == .builtIn(.default))
    #expect(alarm.volume == 0.7)
    #expect(alarm.fadeIn == true)
    #expect(alarm.snoozeMinutes == 9)
    #expect(alarm.isEnabled == true)
}

@Test("알람을 JSON으로 저장했다 읽으면 그대로 복원된다")
func alarmCodableRoundTrip() throws {
    let original = Alarm(
        hour: 8,
        minute: 15,
        weekdays: [.monday, .wednesday, .friday],
        label: "운동",
        source: .spotify(uri: "spotify:playlist:abc123"),
        volume: 0.4,
        fadeIn: false,
        snoozeMinutes: nil,
        isEnabled: false
    )

    let data = try JSONEncoder().encode(original)
    let restored = try JSONDecoder().decode(Alarm.self, from: data)

    #expect(restored == original)
}

@Test("Weekday 값은 Calendar의 weekday 성분과 일치한다")
func weekdayMatchesCalendar() {
    #expect(Weekday.sunday.rawValue == 1)
    #expect(Weekday.saturday.rawValue == 7)
    #expect(Weekday.allCases.count == 7)
}
