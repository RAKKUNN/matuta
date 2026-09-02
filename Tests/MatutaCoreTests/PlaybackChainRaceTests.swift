import Testing
import Foundation
@testable import MatutaCore

@MainActor
private final class SlowAsyncMockSource: SoundSource {
    let sourceRef: SoundSourceRef
    let displayName: String
    let requiresNetwork: Bool
    let needsBackupTone: Bool
    var isPlaying: Bool = false
    var playDelayNanoseconds: UInt64

    init(displayName: String, needsBackupTone: Bool = false, playDelayNanoseconds: UInt64 = 50_000_000) {
        self.sourceRef = .builtIn(name: displayName)
        self.displayName = displayName
        self.requiresNetwork = false
        self.needsBackupTone = needsBackupTone
        self.playDelayNanoseconds = playDelayNanoseconds
    }

    func play(volume: Double, fadeIn: Bool) async throws {
        if playDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: playDelayNanoseconds)
        }
        isPlaying = true
    }

    func stop() {
        isPlaying = false
    }

    func preflight() async -> PreflightResult {
        .ready
    }
}

@Test("start() 실행 도중 stop()이 호출되면 주 소스와 백업 소스 모두 재생되지 않고 즉시 정지된다")
@MainActor
func testPlaybackChainRaceConditionStop() async {
    let chain = PlaybackChain()
    let primary = SlowAsyncMockSource(displayName: "Slow Spotify", needsBackupTone: true, playDelayNanoseconds: 80_000_000)
    let backup = SlowAsyncMockSource(displayName: "Radar Backup", needsBackupTone: false, playDelayNanoseconds: 0)

    let task = Task { @MainActor in
        await chain.start(primary: primary, backup: backup, volume: 0.8, fadeIn: false)
    }

    // primary.play()가 비동기 대기 중일 때 stop() 호출
    try? await Task.sleep(nanoseconds: 20_000_000)
    chain.stop()

    await task.value

    #expect(primary.isPlaying == false)
    #expect(backup.isPlaying == false)
    #expect(chain.isPlayingBackupConcurrently == false)
    #expect(chain.activeSourceName == "")
}
