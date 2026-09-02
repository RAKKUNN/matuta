import SwiftUI
import AppKit
import MatutaCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows where window.identifier?.rawValue == "alarms" {
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
        .windowResizability(.contentSize)

        MenuBarExtra(menuBarTitle) {
            Button("알람 창 열기") {
                openWindow(id: "alarms")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            if let next = model.nextFireDate {
                Text("다음 알람 \(next.formatted(date: .omitted, time: .shortened))")
            } else {
                Text("켜진 알람 없음")
            }
            Divider()
            Button("종료") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }

    /// 메뉴바에는 다음 알람 시각만 조용히 띄운다.
    private var menuBarTitle: String {
        guard let next = model.nextFireDate else { return "⏰" }
        return "⏰ " + next.formatted(date: .omitted, time: .shortened)
    }
}
