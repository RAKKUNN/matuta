import Testing
import Foundation
@testable import MatutaCore

@Test("LanguageResolver: 시스템 언어가 ko로 시작하면 한국어로 해석된다")
func testResolveSystemKorean() {
    #expect(LanguageResolver.resolve(.system, preferredLanguages: ["ko-KR"]) == .korean)
    #expect(LanguageResolver.resolve(.system, preferredLanguages: ["ko"]) == .korean)
    #expect(LanguageResolver.resolve(.system, preferredLanguages: ["KO-KR", "en-US"]) == .korean)
}

@Test("LanguageResolver: 시스템 언어가 ko가 아니거나 비어있으면 영어로 해석된다")
func testResolveSystemEnglish() {
    #expect(LanguageResolver.resolve(.system, preferredLanguages: ["en-US"]) == .english)
    #expect(LanguageResolver.resolve(.system, preferredLanguages: ["ja-JP"]) == .english)
    #expect(LanguageResolver.resolve(.system, preferredLanguages: []) == .english)
}

@Test("LanguageResolver: 수동 설정은 시스템 언어 목록을 무시한다")
func testResolveManualOverride() {
    #expect(LanguageResolver.resolve(.korean, preferredLanguages: ["en-US"]) == .korean)
    #expect(LanguageResolver.resolve(.english, preferredLanguages: ["ko-KR"]) == .english)
}

@Test("ResolvedLanguage: 올바른 Locale 식별자를 반환한다")
func testResolvedLanguageLocale() {
    #expect(ResolvedLanguage.korean.locale.identifier.contains("ko"))
    #expect(ResolvedLanguage.english.locale.identifier.contains("en"))
}
