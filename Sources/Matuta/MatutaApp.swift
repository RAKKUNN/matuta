import SwiftUI
import AppKit
import MatutaCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            for window in NSApp.windows where window.identifier?.rawValue == "alarms" || window.title == "Matuta" || window.title == "알람" {
                window.center()
                window.minSize = NSSize(width: 380, height: 440)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows where window.identifier?.rawValue == "alarms" || window.title == "Matuta" || window.title == "알람" {
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

    // App 구조체는 @MainActor 상태를 소유하지 않는다.
    // 상태는 각 씬의 루트 뷰가 싱글턴에서 읽는다. 이유는
    // AlarmListModel.shared 의 주석 참고.
    var body: some Scene {
        Window("Matuta", id: "alarms") {
            RootWindowView()
        }
        .defaultSize(width: 440, height: 600)
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarPopoverView()
        } label: {
            MenuBarLabelView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsRootView()
        }
    }
}

/// 설정 창 내용. 씬 클로저가 `@MainActor` 상태를 만지지 않도록 감싼다.
struct SettingsRootView: View {
    var body: some View {
        SettingsView(language: LanguageSetting.shared)
            .environment(LanguageSetting.shared)
    }
}
