import SwiftUI
import MatutaCore

struct TimePickerView: View {
    @Binding var hour12: Int
    @Binding var minute: Int
    @Binding var isPM: Bool
    let theme: CozyTheme

    @State private var focusedField: TimeFieldFocus = .hour

    enum TimeFieldFocus {
        case hour
        case minute
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // 시/분 디지털 박스
                HStack(spacing: 8) {
                    // 시(Hour) 블록
                    timeUnitBlock(
                        valueString: String(format: "%02d", hour12),
                        isFocused: focusedField == .hour,
                        onTap: { focusedField = .hour },
                        onIncrement: { incrementHour(1) },
                        onDecrement: { incrementHour(-1) }
                    )

                    Text(":")
                        .font(.system(size: 42, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(theme.textSecondary.opacity(0.6))
                        .offset(y: -2)

                    // 분(Minute) 블록
                    timeUnitBlock(
                        valueString: String(format: "%02d", minute),
                        isFocused: focusedField == .minute,
                        onTap: { focusedField = .minute },
                        onIncrement: { incrementMinute(1) },
                        onDecrement: { incrementMinute(-1) }
                    )
                }
                .padding(8)
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(theme.subtleStroke, lineWidth: 1)
                )

                // AM / PM 토글 바
                VStack(spacing: 4) {
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            isPM = false
                        }
                    }) {
                        Text("AM")
                            .font(.system(size: 12, weight: !isPM ? .bold : .medium))
                            .frame(width: 46, height: 28)
                            .background(!isPM ? theme.accent : (theme.isLight ? Color.black.opacity(0.06) : Color.white.opacity(0.06)))
                            .foregroundStyle(!isPM ? Color.white : theme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            isPM = true
                        }
                    }) {
                        Text("PM")
                            .font(.system(size: 12, weight: isPM ? .bold : .medium))
                            .frame(width: 46, height: 28)
                            .background(isPM ? theme.accent : (theme.isLight ? Color.black.opacity(0.06) : Color.white.opacity(0.06)))
                            .foregroundStyle(isPM ? Color.white : theme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 퀵 타임 프리셋 칩
            HStack(spacing: 6) {
                quickTimeChip("06:30", h: 6, m: 30, pm: false)
                quickTimeChip("07:00", h: 7, m: 0, pm: false)
                quickTimeChip("07:30", h: 7, m: 30, pm: false)
                quickTimeChip("08:00", h: 8, m: 0, pm: false)
                quickTimeChip("08:30", h: 8, m: 30, pm: false)
            }
        }
    }

    private func timeUnitBlock(
        valueString: String,
        isFocused: Bool,
        onTap: @escaping () -> Void,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 2) {
            Button(action: onIncrement) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isFocused ? theme.accent : theme.textTertiary)
                    .frame(width: 60, height: 14)
            }
            .buttonStyle(.plain)

            Button(action: onTap) {
                Text(valueString)
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isFocused ? (theme.isLight ? theme.accent : Color.white) : theme.textSecondary)
                    .frame(width: 64, height: 48)
                    .background(isFocused ? theme.accent.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onDecrement) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isFocused ? theme.accent : theme.textTertiary)
                    .frame(width: 60, height: 14)
            }
            .buttonStyle(.plain)
        }
    }

    private func incrementHour(_ delta: Int) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            var next = hour12 + delta
            if next > 12 { next = 1 }
            if next < 1 { next = 12 }
            hour12 = next
        }
    }

    private func incrementMinute(_ delta: Int) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            var next = minute + delta
            if next > 59 { next = 0 }
            if next < 0 { next = 59 }
            minute = next
        }
    }

    private func quickTimeChip(_ label: String, h: Int, m: Int, pm: Bool) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                hour12 = h
                minute = m
                isPM = pm
            }
        }) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(theme.cardBackground)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(theme.subtleStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
