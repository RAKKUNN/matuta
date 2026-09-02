import Foundation
import AppKit
import MatutaCore

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
        NSWorkspace.shared.open(url)
    }

    func stop() {
        // 브라우저 탭은 앱에서 직접 닫지 않음
    }
}
