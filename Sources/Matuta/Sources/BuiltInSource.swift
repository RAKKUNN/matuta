import Foundation
import MatutaCore

@MainActor
final class BuiltInSource: SoundSource {
    let sourceRef: SoundSourceRef
    let name: String
    private let player: TonePlayer

    var displayName: String {
        "🔔 \(name)"
    }

    var requiresNetwork: Bool { false }
    var needsBackupTone: Bool { false }

    init(name: String = "Radar", player: TonePlayer = TonePlayer()) {
        self.name = name
        self.sourceRef = .builtIn(name: name)
        self.player = player
    }

    func preflight() async -> PreflightResult {
        return .ready
    }

    func play(volume: Double, fadeIn: Bool) async throws {
        let pattern = TonePattern.pattern(named: name)
        player.start(pattern: pattern, volume: volume, fadeIn: fadeIn)
    }

    func stop() {
        player.stop()
    }
}
