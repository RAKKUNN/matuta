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
    /// 스크립트가 `play`만 보내므로 음악 앱의 큐가 비어 있으면 오류 없이 무음이 된다.
    /// 재생 성공을 검증할 수 없는 소스이므로 백업음을 함께 재생한다 (설계 문서 §7.4).
    var needsBackupTone: Bool { true }

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
