import Testing
import Foundation
@testable import MatutaCore

@MainActor
private final class MockSource: SoundSource {
    let sourceRef: SoundSourceRef
    let displayName: String
    let requiresNetwork: Bool
    let needsBackupTone: Bool
    var shouldThrow: Bool
    var played: Bool = false
    var playedVolume: Double?
    var stopped: Bool = false

    init(
        sourceRef: SoundSourceRef,
        displayName: String,
        requiresNetwork: Bool = false,
        needsBackupTone: Bool = false,
        shouldThrow: Bool = false
    ) {
        self.sourceRef = sourceRef
        self.displayName = displayName
        self.requiresNetwork = requiresNetwork
        self.needsBackupTone = needsBackupTone
        self.shouldThrow = shouldThrow
    }

    func preflight() async -> PreflightResult { .ready }

    func play(volume: Double, fadeIn: Bool) async throws {
        if shouldThrow {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Playback failed"])
        }
        played = true
        playedVolume = volume
    }

    func stop() {
        stopped = true
    }
}

@MainActor
@Test("정상 소스는 주 소스만 단독으로 재생된다")
func normalSourcePlaysAlone() async {
    let chain = PlaybackChain()
    let primary = MockSource(sourceRef: .builtIn(name: "Radar"), displayName: "Radar")
    let backup = MockSource(sourceRef: .builtIn(name: "Radar"), displayName: "Radar")

    await chain.start(primary: primary, backup: backup, volume: 0.8, fadeIn: false)

    #expect(primary.played == true)
    #expect(primary.playedVolume == 0.8)
    #expect(backup.played == false)
    #expect(chain.isPlayingBackupConcurrently == false)
}

@MainActor
@Test("주 소스 재생 실패 시 백업음으로 자동 폴백한다")
func failingSourceFallsBackToBackup() async {
    let chain = PlaybackChain()
    let primary = MockSource(sourceRef: .streamURL(URL(string: "https://invalid.url")!), displayName: "스트림", shouldThrow: true)
    let backup = MockSource(sourceRef: .builtIn(name: "Radar"), displayName: "Radar")

    await chain.start(primary: primary, backup: backup, volume: 0.7, fadeIn: true)

    #expect(primary.played == false)
    #expect(backup.played == true)
    #expect(backup.playedVolume == 0.7)
    #expect(chain.isPlayingBackupConcurrently == false)
    #expect(chain.activeSourceName.contains("Radar"))
}

@MainActor
@Test("검증 불가능한 소스(needsBackupTone)는 백업음과 동시 재생된다")
func unverifiableSourcePlaysConcurrentlyWithBackup() async {
    let chain = PlaybackChain()
    let primary = MockSource(sourceRef: .spotify(uri: "spotify:track:123"), displayName: "Spotify", needsBackupTone: true)
    let backup = MockSource(sourceRef: .builtIn(name: "Radar"), displayName: "Radar")

    await chain.start(primary: primary, backup: backup, volume: 0.9, fadeIn: false)

    #expect(primary.played == true)
    #expect(backup.played == true)
    #expect(chain.isPlayingBackupConcurrently == true)
}

@MainActor
@Test("stop 호출 시 모든 재생 중인 소스를 중지한다")
func stopTerminatesAllSources() async {
    let chain = PlaybackChain()
    let primary = MockSource(sourceRef: .spotify(uri: "spotify:track:123"), displayName: "Spotify", needsBackupTone: true)
    let backup = MockSource(sourceRef: .builtIn(name: "Radar"), displayName: "Radar")

    await chain.start(primary: primary, backup: backup, volume: 0.9, fadeIn: false)
    chain.stop()

    #expect(primary.stopped == true)
    #expect(backup.stopped == true)
}
