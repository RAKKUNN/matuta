import SwiftUI
import MatutaCore

// MARK: - Raycast/Dato 스타일 대화형 메뉴바 팝오버 뷰

struct MenuBarPopoverView: View, Localizable {
    @Environment(LanguageSetting.self) var language
    @Environment(\.openWindow) private var openWindow

    private var theme: CozyTheme {
        ThemeManager.shared.current
    }

    var body: some View {
        @Bindable var model = AlarmListModel.shared

        VStack(spacing: 12) {
            // 알람 울림 중일 때 즉시 끄기 배너
            if model.firing != nil {
                Button(action: { model.dismissFiring() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(t(.dismissAlarmSpace))
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .shadow(color: theme.accent.opacity(0.3), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
            }

            // 다음 알람 카드 & 토글 스위치
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t(.nextAlarm))
                        .font(.system(size: 10, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundStyle(theme.textTertiary)

                    if let next = model.nextFireDate {
                        Text(next.formatted(.dateTime.hour().minute().locale(language.locale)))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(theme.textPrimary)
                    } else {
                        Text(t(.noActiveAlarmsShort))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                Spacer()

                if let alarm = model.nextAlarm {
                    CozyToggle(isOn: Binding(
                        get: { alarm.isEnabled },
                        set: { _ in model.toggle(alarm) }
                    ), accent: theme.accent)
                }
            }
            .padding(12)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(theme.subtleStroke, lineWidth: 1)
            )

            // 원터치 퀵 낮잠 칩
            HStack(spacing: 6) {
                quickNapButton(model: model, textKey: .quickNap20, minutes: 20, icon: "cup.and.saucer.fill")
                quickNapButton(model: model, textKey: .quickNap45, minutes: 45, icon: "book.fill")
                quickNapButton(model: model, textKey: .quickNap60, minutes: 60, icon: "moon.zzz.fill")
            }

            Divider().opacity(theme.isLight ? 0.08 : 0.12)

            // 하단 바로가기 액션 바
            HStack {
                Button(action: {
                    openWindow(id: "alarms")
                    NSApp.activate(ignoringOtherApps: true)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(t(.openAlarmsWindow))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(theme.textSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    model.openNightstand()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 10))
                        Text(t(.nightstand))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(theme.accent)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(t(.quit)) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(theme.textTertiary)
            }
        }
        .padding(14)
        .frame(width: 290)
        .background(theme.baseBackground)
    }

    private func quickNapButton(model: AlarmListModel, textKey: LocalizedText, minutes: Int, icon: String) -> some View {
        Button(action: {
            let target = Date().addingTimeInterval(Double(minutes) * 60)
            let calendar = Calendar.current
            let h = calendar.component(.hour, from: target)
            let m = calendar.component(.minute, from: target)
            let label = t(textKey)
            let alarm = Alarm(
                hour: h,
                minute: m,
                weekdays: [],
                label: label,
                source: .builtIn(.default),
                volume: 0.8,
                fadeIn: true,
                snoozeMinutes: 9,
                isEnabled: true
            )
            model.save(alarm)
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(t(textKey))
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(theme.textSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4.5)
            .background(theme.cardBackground)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(theme.subtleStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
