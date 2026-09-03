import Foundation
import MatutaCore

@MainActor
final class BuiltInSource: SoundSource {
    let sourceRef: SoundSourceRef
    let tone: BuiltInTone
    private let player: TonePlayer

    var displayName: String {
        "🔔 \(tone.rawValue)"
    }

    var requiresNetwork: Bool { false }
    var needsBackupTone: Bool { false }

    init(tone: BuiltInTone = .default, player: TonePlayer = TonePlayer()) {
        self.tone = tone
        self.sourceRef = .builtIn(tone)
        self.player = player
    }

    func preflight() async -> PreflightResult {
        return .ready
    }

    func play(volume: Double, fadeIn: Bool) async throws {
        let pattern = TonePattern.pattern(for: tone)
        player.start(pattern: pattern, volume: volume, fadeIn: fadeIn)
    }

    func stop() {
        player.stop()
    }
}
