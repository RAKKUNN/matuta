import SwiftUI
import MatutaCore

@main
struct MatutaApp: App {
    @State private var model = AlarmListModel()

    var body: some Scene {
        Window("알람", id: "alarms") {
            AlarmListView(model: model)
        }
        .windowResizability(.contentSize)

        MenuBarExtra(menuBarTitle) {
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
