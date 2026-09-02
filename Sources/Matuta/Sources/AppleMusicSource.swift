import Foundation
import AppKit
import MatutaCore

@MainActor
final class AppleMusicSource: SoundSource {
    let sourceRef: SoundSourceRef
    let id: String

    var displayName: String {
        "🍎 Apple Music"
    }

    var requiresNetwork: Bool { true }
    var needsBackupTone: Bool { false }

    init(id: String) {
        self.id = id
        self.sourceRef = .appleMusic(id: id)
    }

    func preflight() async -> PreflightResult {
        return .ready
    }

    func play(volume: Double, fadeIn: Bool) async throws {
        if let url = URL(string: id), url.scheme?.hasPrefix("http") == true {
            NSWorkspace.shared.open(url)
        }

        let scriptSource = """
        tell application "Music"
            activate
            play
        end tell
        """
        if let script = NSAppleScript(source: scriptSource) {
            var errorInfo: NSDictionary?
            script.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                throw NSError(domain: "AppleMusicSource", code: 1, userInfo: [NSLocalizedDescriptionKey: error.description])
            }
        }
    }

    func stop() {
        let scriptSource = """
        tell application "Music"
            pause
        end tell
        """
        if let script = NSAppleScript(source: scriptSource) {
            var errorInfo: NSDictionary?
            script.executeAndReturnError(&errorInfo)
        }
    }
}
