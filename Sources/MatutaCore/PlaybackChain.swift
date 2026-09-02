import Foundation

/// 소스 재생을 총괄하고, 실패 시 자동 폴백 및 미검증 소스 동시 재생을 담당하는 오케스트레이터.
///
/// 설계 문서 §7.4:
/// - 검증 가능한 소스 (내장, 로컬 파일, 스트림 URL, Apple Music) — 실패하면 백업음(Radar)으로 순차 폴백.
/// - 검증 불가능한 소스 (Spotify, 웹) — 외부 앱/브라우저가 열리며, 내장 사운드를 낮은 볼륨으로 동시에 재생.
@MainActor
public final class PlaybackChain {
    private var primarySource: SoundSource?
    private var backupSource: SoundSource?

    public private(set) var isPlayingBackupConcurrently: Bool = false
    public private(set) var activeSourceName: String = ""

    public init() {}

    public func start(
        primary: SoundSource,
        backup: SoundSource,
        volume: Double,
        fadeIn: Bool
    ) async {
        stop()

        self.primarySource = primary
        self.backupSource = backup

        if primary.needsBackupTone {
            // 검증 불가능 소스: 주 소스 실행 + 백업음 동시 재생
            isPlayingBackupConcurrently = true
            activeSourceName = "\(primary.displayName) (백업음 동시 재생)"

            // 주 소스 실행 (Spotify 실행 / 웹 URL 오픈 등)
            try? await primary.play(volume: volume, fadeIn: fadeIn)

            // 백업음을 안전한 저볼륨(15~20%)으로 동시 재생
            let safeBackupVol = max(0.15 * volume, 0.1)
            try? await backup.play(volume: safeBackupVol, fadeIn: false)
        } else {
            // 검증 가능 소스: 주 소스 시도 후 실패 시 백업음으로 폴백
            isPlayingBackupConcurrently = false
            activeSourceName = primary.displayName

            do {
                try await primary.play(volume: volume, fadeIn: fadeIn)
            } catch {
                activeSourceName = "\(backup.displayName) (폴백)"
                try? await backup.play(volume: volume, fadeIn: fadeIn)
            }
        }
    }

    public func stop() {
        primarySource?.stop()
        backupSource?.stop()
        primarySource = nil
        backupSource = nil
        isPlayingBackupConcurrently = false
        activeSourceName = ""
    }
}
