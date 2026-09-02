import SwiftUI
import MatutaCore

struct AlarmEditView: View {
    @State private var alarm: Alarm
    private let onSave: (Alarm) -> Void
    private let onCancel: () -> Void

    init(
        alarm: Alarm,
        onSave: @escaping (Alarm) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _alarm = State(initialValue: alarm)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 18) {
            timeField
            weekdayPicker
            soundSection
            volumeSection

            HStack {
                Button("취소", role: .cancel) { onCancel() }
                Spacer()
                Button("저장") { onSave(alarm) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 340)
    }

    // 드럼 휠 대신 키보드로 친다. Mac에는 키보드가 있다.
    private var timeField: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                TextField("", value: $alarm.hour, format: .number)
                    .frame(width: 62)
                Text(":")
                TextField("", value: $alarm.minute, format: .number)
                    .frame(width: 62)
            }
            .textFieldStyle(.plain)
            .font(.system(size: 42, weight: .thin))
            .monospacedDigit()
            .multilineTextAlignment(.center)

            Text("숫자를 입력하세요")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .onChange(of: alarm.hour) { _, new in
            alarm.hour = min(23, max(0, new))
        }
        .onChange(of: alarm.minute) { _, new in
            alarm.minute = min(59, max(0, new))
        }
    }

    private var weekdayPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("반복").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                ForEach(Weekday.displayOrder, id: \.self) { day in
                    Button(day.shortName) {
                        if alarm.weekdays.contains(day) {
                            alarm.weekdays.remove(day)
                        } else {
                            alarm.weekdays.insert(day)
                        }
                    }
                    .buttonStyle(.borderless)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(alarm.weekdays.contains(day) ? Color.accentColor : Color.secondary.opacity(0.15))
                    .foregroundStyle(alarm.weekdays.contains(day) ? Color.white : Color.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    // 2단계에서 옴니박스가 이 자리를 대체한다.
    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("무엇으로 깨울까요").font(.caption).foregroundStyle(.secondary)
            HStack {
                Image(systemName: "bell.fill")
                Text("Radar")
                Spacer()
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("볼륨").font(.caption).foregroundStyle(.secondary)
            Slider(value: $alarm.volume, in: 0...1)
            Toggle("서서히 커지기", isOn: $alarm.fadeIn)
            Toggle("스누즈 9분", isOn: Binding(
                get: { alarm.snoozeMinutes != nil },
                set: { alarm.snoozeMinutes = $0 ? 9 : nil }
            ))
        }
    }
}
