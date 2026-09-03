import Testing
import Foundation
@testable import MatutaCore

@Test("Spotify URI를 정확히 판별한다")
func parseSpotifyURI() {
    let input = "spotify:track:6rqhFgbbKwnb9MLmUQDhG6"
    let source = OmniboxParser.parse(text: input)
    #expect(source == .spotify(uri: "spotify:track:6rqhFgbbKwnb9MLmUQDhG6"))
}

@Test("Spotify 웹 링크를 spotify URI로 변환하여 판별한다")
func parseSpotifyWebLink() {
    let input = "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abc"
    let source = OmniboxParser.parse(text: input)
    #expect(source == .spotify(uri: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M"))
}

@Test("Apple Music 링크를 판별한다")
func parseAppleMusicLink() {
    let input = "https://music.apple.com/kr/album/daybreak/1234567890?i=987654321"
    let source = OmniboxParser.parse(text: input)
    #expect(source == .appleMusic(id: input))
}

@Test("스트림 오디오 확장자 및 스트림 URL을 판별한다")
func parseStreamURL() {
    let input = "https://stream.radioparadise.com/aac-320"
    let source = OmniboxParser.parse(text: input)
    #expect(source == .streamURL(URL(string: "https://stream.radioparadise.com/aac-320")!))

    let m3u8Input = "https://example.com/audio/live.m3u8"
    let m3u8Source = OmniboxParser.parse(text: m3u8Input)
    #expect(m3u8Source == .streamURL(URL(string: "https://example.com/audio/live.m3u8")!))
}

@Test("일반 웹 URL을 판별한다")
func parseGenericWebURL() {
    let input = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    let source = OmniboxParser.parse(text: input)
    #expect(source == .web(URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!))
}

@Test("로컬 파일 경로 및 file:// URL을 판별한다")
func parseLocalFilePath() {
    let tempDir = NSTemporaryDirectory()
    let testFilePath = (tempDir as NSString).appendingPathComponent("test_alarm.mp3")
    try? Data("dummy".utf8).write(to: URL(fileURLWithPath: testFilePath))
    defer { try? FileManager.default.removeItem(atPath: testFilePath) }

    let source = OmniboxParser.parse(text: testFilePath)
    if case .localFile = source {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "로컬 파일로 인식되어야 합니다")
    }
}

@Test("일반 텍스트는 내장 사운드로 판별한다")
func parsePlainTextBuiltIn() {
    let input = "Radar"
    let source = OmniboxParser.parse(text: input)
    #expect(source == .builtIn(.radar))

    let empty = OmniboxParser.parse(text: "")
    #expect(empty == .builtIn(.default))
}
