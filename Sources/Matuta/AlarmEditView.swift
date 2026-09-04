import SwiftUI
import MatutaCore

struct AlarmEditView: View, Localizable {
    @State private var alarm: Alarm
    @State private var isPM: Bool = false
    @State private var hour12: Int = 7
    @Environment(LanguageSetting.self) var language

    private let onSave: (Alarm) -> Void
    private let onCancel: () -> Void

    private var theme: CozyTheme {
        ThemeManager.shared.current
    }

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
        VStack(spacing: 0) {
            // 상단 네비게이션 헤더
            headerBar

            Divider().opacity(theme.isLight ? 0.08 : 0.12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. 시간 선택기 (스마트 스컬프터)
                    TimePickerView(
                        hour12: $hour12,
                        minute: $alarm.minute,
                        isPM: $isPM,
                        theme: theme
                    )

                    // 2. 반복 요일 선택기
                    WeekdayPickerView(
                        weekdays: $alarm.weekdays,
                        theme: theme
                    )

                    // 3. 사운드 옴니박스 (스마트 자동 판별 및 브라우즈)
                    SoundOmniboxView(
                        soundRef: $alarm.source,
                        theme: theme
                    )

                    // 4. 라벨, 볼륨 및 옵션
                    AlarmOptionsView(
                        label: $alarm.label,
                        volume: $alarm.volume,
                        fadeIn: $alarm.fadeIn,
                        snoozeMinutes: $alarm.snoozeMinutes,
                        theme: theme
                    )
                }
                .padding(22)
            }
        }
        .frame(width: 440, height: 620)
        .background(theme.baseBackground)
        .onAppear {
            initializeTime()
        }
    }

    private var headerBar: some View {
        HStack {
            Button(t(.cancel)) {
                onCancel()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(theme.textSecondary)

            Spacer()

            Text(t(.editAlarm))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Button(t(.save)) {
                syncTime24()
                onSave(alarm)
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(theme.isLight ? Color.white : Color.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(theme.isLight ? theme.accent : Color.white)
            .clipShape(Capsule())
            .shadow(color: theme.accent.opacity(0.25), radius: 8, y: 2)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func initializeTime() {
        isPM = alarm.hour >= 12
        hour12 = alarm.hour == 0 ? 12 : (alarm.hour > 12 ? alarm.hour - 12 : alarm.hour)
    }

    private func syncTime24() {
        if isPM {
            alarm.hour = hour12 == 12 ? 12 : hour12 + 12
        } else {
            alarm.hour = hour12 == 12 ? 0 : hour12
        }
    }
}
