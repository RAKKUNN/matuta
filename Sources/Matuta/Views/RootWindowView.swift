import SwiftUI
import MatutaCore

/// 메인 창의 내용. App 씬 클로저가 `@MainActor` 상태를 직접 만지지 않도록
/// 한 겹 감싼다.
struct RootWindowView: View {
    var body: some View {
        AlarmListView(model: AlarmListModel.shared)
            .environment(LanguageSetting.shared)
    }
}
