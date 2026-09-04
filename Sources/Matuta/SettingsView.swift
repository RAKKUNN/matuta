import SwiftUI
import MatutaCore

struct SettingsView: View, Localizable {
    @Bindable var language: LanguageSetting

    private var theme: CozyTheme {
        ThemeManager.shared.current
    }

    var body: some View {
        Form {
            Section {
                Picker(t(.language), selection: $language.selection) {
                    Text(t(.languageSystem)).tag(AppLanguage.system)
                    Text(t(.languageKorean)).tag(AppLanguage.korean)
                    Text(t(.languageEnglish)).tag(AppLanguage.english)
                }
                .pickerStyle(.segmented)
            } header: {
                Text(t(.language))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 320, height: 120)
    }
}
