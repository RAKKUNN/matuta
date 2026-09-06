import Foundation
import AppKit
import MatutaCore

/// 외부 앱·브라우저를 열되 전면으로 가져오지 않는다.
///
/// 기본 `NSWorkspace.open(_:)` 은 대상 앱을 활성화하므로 알람 오버레이가
/// 키 창 지위를 잃는다. 그러면 스페이스바가 브라우저로 가고(YouTube 에서는
/// 재생/일시정지로 먹힌다) 알람이 꺼지지 않는다. 오버레이는 .screenSaver
/// 레벨이라 어차피 화면을 덮으므로 활성화해서 얻는 것이 없다.
@MainActor
func openWithoutActivating(_ url: URL) {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = false
    NSWorkspace.shared.open(url, configuration: configuration)
}

@MainActor
final class WebSource: SoundSource {
    let sourceRef: SoundSourceRef
    let url: URL

    var displayName: String {
        "🌐 \(url.host ?? "웹")"
    }

    var requiresNetwork: Bool { true }
    var needsBackupTone: Bool { true }

    init(url: URL) {
        self.url = url
        self.sourceRef = .web(url)
    }

    func preflight() async -> PreflightResult {
        return .ready
    }

    func play(volume: Double, fadeIn: Bool) async throws {
        openWithoutActivating(url)
    }

    func stop() {
        // 브라우저 탭은 앱에서 직접 닫지 않음
    }
}
