import SwiftUI
import MatutaCore

struct WeekdayPickerView: View {
    @Binding var weekdays: Set<Weekday>
    let theme: CozyTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("반복")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.textSecondary)

                Spacer()

                HStack(spacing: 4) {
                    quickDayPreset("주중", days: [.monday, .tuesday, .wednesday, .thursday, .friday])
                    quickDayPreset("주말", days: [.saturday, .sunday])
                    quickDayPreset("매일", days: Set(Weekday.allCases))
                    quickDayPreset("1회성", days: [])
                }
            }

            HStack(spacing: 6) {
                ForEach(Weekday.displayOrder, id: \.self) { day in
                    let isSelected = weekdays.contains(day)
                    Button(action: {
                        if isSelected {
                            weekdays.remove(day)
                        } else {
                            weekdays.insert(day)
                        }
                    }) {
                        Text(day.shortName)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(isSelected ? theme.accent : theme.cardBackground)
                            .foregroundStyle(isSelected ? Color.white : theme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(isSelected ? Color.clear : theme.subtleStroke, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickDayPreset(_ title: String, days: Set<Weekday>) -> some View {
        Button(action: { weekdays = days }) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.textTertiary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(theme.cardBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
