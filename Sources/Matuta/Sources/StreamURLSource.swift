import Foundation
import AVFoundation
import MatutaCore

@MainActor
final class StreamURLSource: SoundSource {
    let sourceRef: SoundSourceRef
    let url: URL
    private var player: AVPlayer?

    var displayName: String {
        let host = url.host ?? url.absoluteString
        return "📻 \(host)"
    }

    var requiresNetwork: Bool { true }
    var needsBackupTone: Bool { false }

    init(url: URL) {
        self.url = url
        self.sourceRef = .streamURL(url)
    }

    func preflight() async -> PreflightResult {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3.0

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...399).contains(httpResponse.statusCode) {
                return .ready
            }
            return .warning("스트림 서버 응답 코드: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        } catch {
            return .warning("스트림 서버에 연결할 수 없습니다: \(error.localizedDescription)")
        }
    }

    func play(volume: Double, fadeIn: Bool) async throws {
        stop()

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        player.volume = Float(volume)
        player.play()
        self.player = player
    }

    func stop() {
        player?.pause()
        player = nil
    }
}
