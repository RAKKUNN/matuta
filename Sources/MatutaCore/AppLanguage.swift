import Foundation

public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case system
    case korean = "ko"
    case english = "en"
}

/// 실제로 문자열을 고를 때 쓰는 구체 언어 값. (.system이 여기서 사라짐)
public enum ResolvedLanguage: String, Sendable, CaseIterable {
    case korean
    case english

    public var locale: Locale {
        switch self {
        case .korean:
            return Locale(identifier: "ko_KR")
        case .english:
            return Locale(identifier: "en_US")
        }
    }
}

public enum LanguageResolver {
    /// 시스템 설정 언어 목록을 바탕으로 언어를 결정하는 순수 함수.
    /// 첫 번째 선호 언어가 "ko"로 시작하면 한국어, 아니면 영어.
    public static func resolve(
        _ setting: AppLanguage,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> ResolvedLanguage {
        switch setting {
        case .korean:
            return .korean
        case .english:
            return .english
        case .system:
            if let first = preferredLanguages.first?.lowercased(), first.hasPrefix("ko") {
                return .korean
            }
            return .english
        }
    }
}
