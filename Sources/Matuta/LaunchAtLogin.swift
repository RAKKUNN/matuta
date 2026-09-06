import Foundation
import ServiceManagement

/// 로그인 항목 등록을 감싼다. 시스템을 읽고 쓰기만 하고 판정은 하지 않는다.
/// 판정은 `PreflightEvaluator` 가 한다.
@MainActor
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // 등록에 실패해도 앱은 계속 동작해야 한다.
            // 실패하면 isEnabled 가 false 로 남고 프리플라이트가 다시 경고한다.
        }
    }
}
