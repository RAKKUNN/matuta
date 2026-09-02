import Foundation

/// 알람이 무엇으로 울릴지를 가리키는 식별자. 재생 방법은 갖고 있지 않다.
///
/// 1단계에서 실제로 재생되는 것은 `.builtIn`뿐이다. 나머지는 2단계에서
/// `SoundSource` 프로토콜 구현이 붙는다. 모델을 나중에 고치지 않으려고
/// 여섯 가지를 지금 전부 정의해둔다.
public enum SoundSourceRef: Codable, Equatable, Sendable {
    case builtIn(name: String)
    case localFile(bookmark: Data)
    case streamURL(URL)
    case appleMusic(id: String)
    case spotify(uri: String)
    case web(URL)
}
