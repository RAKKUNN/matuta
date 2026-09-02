import SwiftUI
import MatutaCore

struct AlarmListView: View {
    @Bindable var model: AlarmListModel

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(model.alarms) { alarm in
                    AlarmRow(alarm: alarm) {
                        model.toggle(alarm)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { model.editing = alarm }
                    .contextMenu {
                        Button("삭제", role: .destructive) { model.delete(alarm) }
                    }
                }
            }
            .listStyle(.inset)

            Divider()

            Button {
                model.addAlarm()
            } label: {
                Label("알람 추가", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .padding(8)
        }
        .frame(minWidth: 320, minHeight: 360)
        .navigationTitle("알람")
        .sheet(item: $model.editing) { alarm in
            AlarmEditView(
                alarm: alarm,
                onSave: { updated in
                    model.save(updated)
                    model.editing = nil
                },
                onCancel: { model.editing = nil }
            )
        }
    }
}

private struct AlarmRow: View {
    let alarm: Alarm
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(timeText)
                    .font(.system(size: 30, weight: .light))
                    .monospacedDigit()
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: { _ in onToggle() }))
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .opacity(alarm.isEnabled ? 1.0 : 0.45)
        .padding(.vertical, 4)
    }

    private var timeText: String {
        String(format: "%d:%02d", alarm.hour == 0 ? 12 : (alarm.hour > 12 ? alarm.hour - 12 : alarm.hour), alarm.minute)
            + (alarm.hour < 12 ? " AM" : " PM")
    }

    private var subtitleText: String {
        let days = alarm.weekdays.isEmpty
            ? "한 번만"
            : Weekday.displayOrder
                .filter { alarm.weekdays.contains($0) }
                .map(\.shortName)
                .joined(separator: "·")

        let sourceName: String
        switch alarm.source {
        case .builtIn(let name): sourceName = "🔔 \(name)"
        case .localFile: sourceName = "🎵 파일"
        case .streamURL: sourceName = "📻 라디오"
        case .appleMusic: sourceName = "🍎 Music"
        case .spotify: sourceName = "🟢 Spotify"
        case .web: sourceName = "🌐 웹"
        }

        if let label = alarm.label, !label.isEmpty {
            return "\(days) · \(label) · \(sourceName)"
        }
        return "\(days) · \(sourceName)"
    }
}
