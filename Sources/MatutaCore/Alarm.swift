import Foundation

public struct Alarm: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var hour: Int
    public var minute: Int
    /// 비어 있으면 1회성 알람이다.
    public var weekdays: Set<Weekday>
    public var label: String?
    public var source: SoundSourceRef
    /// 0.0 ... 1.0
    public var volume: Double
    public var fadeIn: Bool
    /// `nil`이면 스누즈 없음.
    public var snoozeMinutes: Int?
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        weekdays: Set<Weekday> = [],
        label: String? = nil,
        source: SoundSourceRef = .builtIn(name: "Radar"),
        volume: Double = 0.7,
        fadeIn: Bool = true,
        snoozeMinutes: Int? = 9,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.label = label
        self.source = source
        self.volume = volume
        self.fadeIn = fadeIn
        self.snoozeMinutes = snoozeMinutes
        self.isEnabled = isEnabled
    }
}
