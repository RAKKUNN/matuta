import SwiftUI
import Observation
import MatutaCore

@MainActor
@Observable
public final class LanguageSetting {
    public static let shared = LanguageSetting()

    private static let storageKey = "MatutaAppLanguage"

    public var selection: AppLanguage {
        didSet {
            persist()
        }
    }

    public var resolved: ResolvedLanguage {
        LanguageResolver.resolve(selection, preferredLanguages: Locale.preferredLanguages)
    }

    public var locale: Locale {
        resolved.locale
    }

    public init() {
        if let saved = UserDefaults.standard.string(forKey: Self.storageKey),
           let lang = AppLanguage(rawValue: saved) {
            self.selection = lang
        } else {
            self.selection = .system
        }
    }

    private func persist() {
        UserDefaults.standard.set(selection.rawValue, forKey: Self.storageKey)
    }
}

@MainActor
public protocol Localizable {
    var language: LanguageSetting { get }
}

extension Localizable {
    public func t(_ key: LocalizedText) -> String {
        Localizer.string(key, language.resolved)
    }
}
