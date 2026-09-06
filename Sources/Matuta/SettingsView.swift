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
                // 섹션 헤더에 같은 "언어"를 또 넣으면 라벨이 두 번 보인다.
                // 행 라벨 하나로 충분하다.
                Picker(t(.language), selection: $language.selection) {
                    Text(t(.languageSystem)).tag(AppLanguage.system)
                    Text(t(.languageKorean)).tag(AppLanguage.korean)
                    Text(t(.languageEnglish)).tag(AppLanguage.english)
                }
                .pickerStyle(.segmented)

                Toggle(t(.launchAtLogin), isOn: Binding(
                    get: { LaunchAtLogin.isEnabled },
                    set: { LaunchAtLogin.setEnabled($0) }
                ))
            }
        }
        .formStyle(.grouped)
        // 세그먼트 3개("System / 한국어 / English")가 줄바꿈 없이 들어갈 폭.
        // 높이를 좁게 잡으면 스크롤바가 생기고 컨트롤이 잘린다.
        .frame(width: 420, height: 180)
    }
}
