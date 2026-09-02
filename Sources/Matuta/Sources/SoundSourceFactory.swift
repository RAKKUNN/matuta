import Foundation
import MatutaCore

@MainActor
enum SoundSourceFactory {
    static func makeSource(for ref: SoundSourceRef, tonePlayer: TonePlayer = TonePlayer()) -> SoundSource {
        switch ref {
        case .builtIn(let name):
            return BuiltInSource(name: name, player: tonePlayer)
        case .localFile(let bookmark):
            return LocalFileSource(bookmark: bookmark)
        case .streamURL(let url):
            return StreamURLSource(url: url)
        case .appleMusic(let id):
            return AppleMusicSource(id: id)
        case .spotify(let uri):
            return SpotifySource(uri: uri)
        case .web(let url):
            return WebSource(url: url)
        }
    }

    static func backupSource(tonePlayer: TonePlayer = TonePlayer()) -> SoundSource {
        return BuiltInSource(name: "Radar", player: tonePlayer)
    }
}
