import Foundation

/// 소스 재생을 총괄하고, 실패 시 자동 폴백 및 미검증 소스 동시 재생을 담당하는 오케스트레이터.
///
/// 설계 문서 §7.4 & 진단서 2.B:
/// - 세대 토큰(generation)을 도입하여 `start()` 비동기 실행 도중 `stop()`이 끼어들어도
///   백업음이나 주 소스가 영구 재생되는 레이스 컨디션을 100% 방지한다.
@MainActor
public final class PlaybackChain {
    private var primarySource: SoundSource?
    private var backupSource: SoundSource?
    private var generation: Int = 0

    public private(set) var isPlayingBackupConcurrently: Bool = false
    public private(set) var activeSourceText: LocalizedText? = nil

    public var activeSourceName: String {
        guard let activeSourceText else { return "" }
        return Localizer.string(activeSourceText, .korean)
    }

    public init() {}

    public func start(
        primary: SoundSource,
        backup: SoundSource,
        volume: Double,
        fadeIn: Bool
    ) async {
        stop()

        generation += 1
        let currentGen = generation

        self.primarySource = primary
        self.backupSource = backup

        if primary.needsBackupTone {
            // 검증 불가능 소스: 주 소스 실행 + 백업음 동시 재생
            isPlayingBackupConcurrently = true
            activeSourceText = .playbackWithBackup(name: primary.displayName)

            // 주 소스 실행 (Spotify / 웹 브라우저 등 지연 가능한 호출)
            try? await primary.play(volume: volume, fadeIn: fadeIn)

            // 실행 중 stop()이 끼어들었거나 세대가 변경되었으면 즉시 정리 후 탈출
            guard currentGen == self.generation else {
                primary.stop()
                backup.stop()
                return
            }

            // 백업음을 안전한 저볼륨(15~20%)으로 동시 재생
            let safeBackupVol = max(0.15 * volume, 0.1)
            try? await backup.play(volume: safeBackupVol, fadeIn: false)

            guard currentGen == self.generation else {
                primary.stop()
                backup.stop()
                return
            }
        } else {
            // 검증 가능 소스: 주 소스 시도 후 실패 시 백업음으로 폴백
            isPlayingBackupConcurrently = false
            activeSourceText = .playbackPrimary(name: primary.displayName)

            do {
                try await primary.play(volume: volume, fadeIn: fadeIn)
                guard currentGen == self.generation else {
                    primary.stop()
                    backup.stop()
                    return
                }
            } catch {
                guard currentGen == self.generation else {
                    primary.stop()
                    backup.stop()
                    return
                }
                activeSourceText = .playbackFallback(name: backup.displayName)
                try? await backup.play(volume: volume, fadeIn: fadeIn)
                guard currentGen == self.generation else {
                    primary.stop()
                    backup.stop()
                    return
                }
            }
        }
    }

    public func stop() {
        generation += 1
        primarySource?.stop()
        backupSource?.stop()
        primarySource = nil
        backupSource = nil
        isPlayingBackupConcurrently = false
        activeSourceText = nil
    }
}
