import Foundation

/// 사용자의 입력을 분석하여 6종 사운드 소스 중 하나로 판별하는 순수 함수.
///
/// 설계 문서 §8.3:
/// 1. 드롭된 파일 또는 파일 경로면 → localFile
/// 2. spotify: 스킴이거나 open.spotify.com 호스트면 → spotify
/// 3. music.apple.com 호스트면 → appleMusic
/// 4. URL이고 오디오 스트림 형식이면 → streamURL
/// 5. 그 밖의 URL이면 → web
/// 6. URL이 아닌 텍스트면 → builtIn (내장 사운드)
public enum OmniboxParser {

    public static func parse(text: String) -> SoundSourceRef {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .builtIn(.default)
        }

        // 1. Spotify URI (e.g. spotify:track:..., spotify:playlist:...)
        if trimmed.hasPrefix("spotify:") {
            return .spotify(uri: trimmed)
        }

        // 2. File URL or File Path
        if trimmed.hasPrefix("file://") {
            if let url = URL(string: trimmed) {
                return makeLocalFileRef(for: url)
            }
        } else if trimmed.hasPrefix("/") && FileManager.default.fileExists(atPath: trimmed) {
            let url = URL(fileURLWithPath: trimmed)
            return makeLocalFileRef(for: url)
        }

        // 3. Web URL inspection
        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            let host = url.host?.lowercased() ?? ""

            // 3.1 Spotify Web Link -> spotify: URI
            if host.contains("open.spotify.com") {
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                if pathComponents.count >= 2 {
                    let type = pathComponents[0]
                    let id = pathComponents[1]
                    return .spotify(uri: "spotify:\(type):\(id)")
                }
                return .spotify(uri: trimmed)
            }

            // 3.2 Apple Music
            if host.contains("music.apple.com") {
                return .appleMusic(id: trimmed)
            }

            // 3.3 Audio Stream URL
            let pathExtension = url.pathExtension.lowercased()
            let streamExtensions = ["m3u8", "aac", "pls", "m3u", "ogg", "opus", "mp3"]
            let lowerPath = url.path.lowercased()
            let fullString = url.absoluteString.lowercased()
            if streamExtensions.contains(pathExtension) ||
               host.contains("stream") || host.contains("radio") ||
               lowerPath.contains("stream") || lowerPath.contains("radio") ||
               fullString.contains("aac-") || fullString.contains("mp3-") {
                return .streamURL(url)
            }

            // 3.4 Generic Web URL
            return .web(url)
        }

        // 4. Default: Built-in Sound
        let matchedTone = BuiltInTone.allCases.first {
            $0.rawValue.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }
        return .builtIn(matchedTone ?? .default)
    }

    public static func makeLocalFileRef(for url: URL) -> SoundSourceRef {
        let bookmark = (try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )) ?? url.path.data(using: .utf8) ?? Data()
        return .localFile(bookmark: bookmark)
    }
}
