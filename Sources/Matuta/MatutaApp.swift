import SwiftUI
import AppKit
import MatutaCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            for window in NSApp.windows where window.identifier?.rawValue == "alarms" || window.title == "알람" {
                window.center()
                window.minSize = NSSize(width: 380, height: 440)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows where window.identifier?.rawValue == "alarms" || window.title == "알람" {
                window.makeKeyAndOrderFront(nil)
                return true
            }
        }
        return true
    }
}

@main
struct MatutaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    @State private var model = AlarmListModel()

    var body: some Scene {
        Window("알람", id: "alarms") {
            AlarmListView(model: model)
        }
        .defaultSize(width: 440, height: 600)
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarPopoverView(model: model)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        if model.firing != nil {
            HStack(spacing: 3) {
                Image(systemName: "bell.and.waveform.fill")
                Text("알람 울림")
            }
        } else if let next = model.nextFireDate {
            HStack(spacing: 3) {
                Image(systemName: "alarm.fill")
                Text(next.formatted(date: .omitted, time: .shortened))
            }
        } else {
            Image(systemName: "alarm")
        }
    }
}

// MARK: - Raycast/Dato 스타일 대화형 메뉴바 팝오버 뷰

private struct MenuBarPopoverView: View {
    @Bindable var model: AlarmListModel
    @Environment(\.openWindow) private var openWindow

    private var theme: CozyTheme {
        ThemeManager.shared.current
    }

    var body: some View {
        VStack(spacing: 12) {
            // 알람 울림 중일 때 즉시 끄기 배너
            if model.firing != nil {
                Button(action: { model.dismissFiring() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("알람 끄기 (Space)")
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
                    Text("다음 알람")
                        .font(.system(size: 10, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundStyle(theme.textTertiary)

                    if let next = model.nextFireDate {
                        Text(next.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(theme.textPrimary)
                    } else {
                        Text("켜진 알람 없음")
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
                quickNapButton(label: "20분 낮잠", minutes: 20, icon: "cup.and.saucer.fill")
                quickNapButton(label: "45분 집중", minutes: 45, icon: "book.fill")
                quickNapButton(label: "1시간 숙면", minutes: 60, icon: "moon.zzz.fill")
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
                        Text("알람 창 열기")
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
                        Text("나이트스탠드")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(theme.accent)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("종료") {
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

    private func quickNapButton(label: String, minutes: Int, icon: String) -> some View {
        Button(action: {
            let target = Date().addingTimeInterval(Double(minutes) * 60)
            let calendar = Calendar.current
            let h = calendar.component(.hour, from: target)
            let m = calendar.component(.minute, from: target)
            let alarm = Alarm(
                hour: h,
                minute: m,
                weekdays: [],
                label: label,
                source: .builtIn(name: "Morning Harp"),
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
                Text(label)
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
