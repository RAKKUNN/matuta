import Foundation

/// 알람이 무엇으로 울릴지를 가리키는 타입 안전한 식별자.
///
/// 진단서 2.H & 덜 끝난 것 1:
/// `BuiltInTone` enum을 직접 연결하여 문자열 기반 하드코딩 및 기본값 갈림을 원천 차단한다.
public enum SoundSourceRef: Equatable, Sendable {
    case builtIn(BuiltInTone)
    case localFile(bookmark: Data)
    case streamURL(URL)
    case appleMusic(id: String)
    case spotify(uri: String)
    case web(URL)
}

extension SoundSourceRef: Codable {
    private enum CodingKeys: String, CodingKey {
        case builtIn
        case localFile
        case streamURL
        case appleMusic
        case spotify
        case web
    }

    private enum BuiltInKeys: String, CodingKey {
        case _0
        case name
        case tone
    }

    private enum LocalFileKeys: String, CodingKey {
        case bookmark
        case _0
    }

    private enum StreamURLKeys: String, CodingKey {
        case _0
    }

    private enum AppleMusicKeys: String, CodingKey {
        case id
        case _0
    }

    private enum SpotifyKeys: String, CodingKey {
        case uri
        case _0
    }

    private enum WebKeys: String, CodingKey {
        case _0
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.builtIn) {
            if let nested = try? container.nestedContainer(keyedBy: BuiltInKeys.self, forKey: .builtIn) {
                if let tone = try? nested.decode(BuiltInTone.self, forKey: ._0) {
                    self = .builtIn(tone)
                    return
                }
                if let name = try? nested.decode(String.self, forKey: .name),
                   let tone = BuiltInTone(rawValue: name) {
                    self = .builtIn(tone)
                    return
                }
                if let tone = try? nested.decode(BuiltInTone.self, forKey: .tone) {
                    self = .builtIn(tone)
                    return
                }
                if let name = try? nested.decode(String.self, forKey: .name) {
                    let matched = BuiltInTone.allCases.first {
                        $0.rawValue.localizedCaseInsensitiveCompare(name) == .orderedSame
                    }
                    self = .builtIn(matched ?? .default)
                    return
                }
            }
            if let tone = try? container.decode(BuiltInTone.self, forKey: .builtIn) {
                self = .builtIn(tone)
                return
            }
            if let name = try? container.decode(String.self, forKey: .builtIn) {
                self = .builtIn(BuiltInTone(rawValue: name) ?? .default)
                return
            }
            self = .builtIn(.default)
            return
        }

        if container.contains(.localFile) {
            if let nested = try? container.nestedContainer(keyedBy: LocalFileKeys.self, forKey: .localFile) {
                if let bookmark = try? nested.decode(Data.self, forKey: .bookmark) {
                    self = .localFile(bookmark: bookmark)
                    return
                }
                if let bookmark = try? nested.decode(Data.self, forKey: ._0) {
                    self = .localFile(bookmark: bookmark)
                    return
                }
            }
            let bookmark = try container.decode(Data.self, forKey: .localFile)
            self = .localFile(bookmark: bookmark)
            return
        }

        if container.contains(.streamURL) {
            if let nested = try? container.nestedContainer(keyedBy: StreamURLKeys.self, forKey: .streamURL),
               let url = try? nested.decode(URL.self, forKey: ._0) {
                self = .streamURL(url)
                return
            }
            let url = try container.decode(URL.self, forKey: .streamURL)
            self = .streamURL(url)
            return
        }

        if container.contains(.appleMusic) {
            if let nested = try? container.nestedContainer(keyedBy: AppleMusicKeys.self, forKey: .appleMusic) {
                if let id = try? nested.decode(String.self, forKey: .id) {
                    self = .appleMusic(id: id)
                    return
                }
                if let id = try? nested.decode(String.self, forKey: ._0) {
                    self = .appleMusic(id: id)
                    return
                }
            }
            let id = try container.decode(String.self, forKey: .appleMusic)
            self = .appleMusic(id: id)
            return
        }

        if container.contains(.spotify) {
            if let nested = try? container.nestedContainer(keyedBy: SpotifyKeys.self, forKey: .spotify) {
                if let uri = try? nested.decode(String.self, forKey: .uri) {
                    self = .spotify(uri: uri)
                    return
                }
                if let uri = try? nested.decode(String.self, forKey: ._0) {
                    self = .spotify(uri: uri)
                    return
                }
            }
            let uri = try container.decode(String.self, forKey: .spotify)
            self = .spotify(uri: uri)
            return
        }

        if container.contains(.web) {
            if let nested = try? container.nestedContainer(keyedBy: WebKeys.self, forKey: .web),
               let url = try? nested.decode(URL.self, forKey: ._0) {
                self = .web(url)
                return
            }
            let url = try container.decode(URL.self, forKey: .web)
            self = .web(url)
            return
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown sound source type")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .builtIn(let tone):
            var nested = container.nestedContainer(keyedBy: BuiltInKeys.self, forKey: .builtIn)
            try nested.encode(tone, forKey: ._0)
        case .localFile(let bookmark):
            var nested = container.nestedContainer(keyedBy: LocalFileKeys.self, forKey: .localFile)
            try nested.encode(bookmark, forKey: .bookmark)
        case .streamURL(let url):
            var nested = container.nestedContainer(keyedBy: StreamURLKeys.self, forKey: .streamURL)
            try nested.encode(url, forKey: ._0)
        case .appleMusic(let id):
            var nested = container.nestedContainer(keyedBy: AppleMusicKeys.self, forKey: .appleMusic)
            try nested.encode(id, forKey: .id)
        case .spotify(let uri):
            var nested = container.nestedContainer(keyedBy: SpotifyKeys.self, forKey: .spotify)
            try nested.encode(uri, forKey: .uri)
        case .web(let url):
            var nested = container.nestedContainer(keyedBy: WebKeys.self, forKey: .web)
            try nested.encode(url, forKey: ._0)
        }
    }
}
