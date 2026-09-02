import Foundation
import AppKit
import MatutaCore

@MainActor
final class SpotifySource: SoundSource {
    let sourceRef: SoundSourceRef
    let uri: String

    var displayName: String {
        "🟢 Spotify"
    }

    var requiresNetwork: Bool { true }
    /// Spotify는 외부 앱이므로 소리 재생 여부를 검증할 수 없음 -> 백업음 동시 재생 필요
    var needsBackupTone: Bool { true }

    init(uri: String) {
        self.uri = uri
        self.sourceRef = .spotify(uri: uri)
    }

    func preflight() async -> PreflightResult {
        if NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") != nil {
            return .ready
        }
        return .warning("Spotify 앱이 설치되어 있지 않습니다. 웹 또는 백업음으로 대체됩니다.")
    }

    func play(volume: Double, fadeIn: Bool) async throws {
        if let url = URL(string: uri) {
            NSWorkspace.shared.open(url)
        }

        let scriptSource = """
        tell application "Spotify"
            play track "\(uri)"
        end tell
        """
        if let script = NSAppleScript(source: scriptSource) {
            var errorInfo: NSDictionary?
            script.executeAndReturnError(&errorInfo)
        }
    }

    func stop() {
        let scriptSource = """
        tell application "Spotify"
            pause
        end tell
        """
        if let script = NSAppleScript(source: scriptSource) {
            var errorInfo: NSDictionary?
            script.executeAndReturnError(&errorInfo)
        }
    }
}
