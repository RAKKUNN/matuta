import Testing
import Foundation
@testable import MatutaCore

/// `SoundSourceRef`는 손으로 쓴 Codable 구현을 갖고 있고, 알람 파일 전체의 관문이다.
/// 여기서 실패하면 사용자의 알람이 통째로 격리된다. 6종 전부 왕복을 검증한다.

private func roundTrip(_ ref: SoundSourceRef) throws -> SoundSourceRef {
    let data = try JSONEncoder().encode(ref)
    return try JSONDecoder().decode(SoundSourceRef.self, from: data)
}

private func decode(_ json: String) throws -> SoundSourceRef {
    try JSONDecoder().decode(SoundSourceRef.self, from: Data(json.utf8))
}

@Test("6종 소스가 전부 인코딩·디코딩 왕복을 견딘다")
func allSourceKindsRoundTrip() throws {
    let cases: [SoundSourceRef] = [
        .builtIn(.morningHarp),
        .builtIn(.radar),
        .localFile(bookmark: Data([0x01, 0x02, 0x03])),
        .streamURL(URL(string: "https://stream.example.com/radio.mp3")!),
        .appleMusic(id: "1234567890"),
        .spotify(uri: "spotify:playlist:abc123"),
        .web(URL(string: "https://www.youtube.com/watch?v=abc")!),
    ]

    for original in cases {
        #expect(try roundTrip(original) == original)
    }
}

@Test("구 포맷 {\"builtIn\":{\"name\":\"...\"}} 을 읽는다")
func decodesLegacyBuiltInNameKey() throws {
    let ref = try decode(#"{"builtIn":{"name":"Morning Harp"}}"#)
    #expect(ref == .builtIn(.morningHarp))
}

@Test("모르는 벨소리 이름은 실패하지 않고 기본값으로 떨어진다")
func unknownToneFallsBackToDefault() throws {
    // 이게 없으면 알람 파일 전체가 격리된다.
    let ref = try decode(#"{"builtIn":{"name":"존재하지 않는 벨소리"}}"#)
    #expect(ref == .builtIn(.default))
}

@Test("대소문자가 달라도 벨소리를 찾아낸다")
func toneNameIsCaseInsensitive() throws {
    let ref = try decode(#"{"builtIn":{"name":"morning harp"}}"#)
    #expect(ref == .builtIn(.morningHarp))
}

@Test("실제 저장 파일에 있던 web 소스 포맷을 읽는다")
func decodesRealWorldWebSource() throws {
    let json = #"{"web":{"_0":"https:\/\/www.youtube.com\/watch?v=PmOpnSuGxbc&list=PLp5&index=10"}}"#
    let ref = try decode(json)
    guard case .web(let url) = ref else {
        Issue.record("web 케이스로 디코딩되지 않았다: \(ref)")
        return
    }
    #expect(url.host == "www.youtube.com")
}

@Test("알람 전체가 왕복해도 소스가 보존된다")
func alarmRoundTripPreservesSource() throws {
    let alarm = Alarm(
        hour: 7, minute: 30,
        weekdays: [.monday, .friday],
        source: .spotify(uri: "spotify:playlist:xyz")
    )
    let data = try JSONEncoder().encode(alarm)
    let restored = try JSONDecoder().decode(Alarm.self, from: data)
    #expect(restored == alarm)
    #expect(restored.source == .spotify(uri: "spotify:playlist:xyz"))
}
