import Foundation
import AVFAudio
import MatutaCore

@MainActor
final class LocalFileSource: SoundSource {
    let sourceRef: SoundSourceRef
    let bookmark: Data
    private var audioPlayer: AVAudioPlayer?
    private var resolvedURL: URL?

    var displayName: String {
        if let url = resolvedURL {
            return "🎵 \(url.lastPathComponent)"
        }
        return "🎵 로컬 파일"
    }

    var requiresNetwork: Bool { false }
    var needsBackupTone: Bool { false }

    init(bookmark: Data) {
        self.bookmark = bookmark
        self.sourceRef = .localFile(bookmark: bookmark)
        self.resolvedURL = Self.resolve(bookmark: bookmark)
    }

    static func resolve(bookmark: Data) -> URL? {
        var isStale = false
        if let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) {
            return url
        }
        if let path = String(data: bookmark, encoding: .utf8), FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    func preflight() async -> PreflightResult {
        guard let url = resolvedURL ?? Self.resolve(bookmark: bookmark) else {
            return .error("파일 경로를 찾을 수 없습니다.")
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .error("파일이 존재하지 않습니다: \(url.lastPathComponent)")
        }
        return .ready
    }

    func play(volume: Double, fadeIn: Bool) async throws {
        stop()

        guard let url = resolvedURL ?? Self.resolve(bookmark: bookmark) else {
            throw NSError(domain: "LocalFileSource", code: 404, userInfo: [NSLocalizedDescriptionKey: "파일을 찾을 수 없습니다."])
        }

        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }

        let player = try AVAudioPlayer(contentsOf: url)
        player.numberOfLoops = -1 // 무한 반복
        player.volume = Float(volume)
        player.prepareToPlay()
        player.play()
        self.audioPlayer = player
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
