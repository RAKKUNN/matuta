import SwiftUI
import MatutaCore

struct AlarmOptionsView: View, Localizable {
    @Binding var label: String?
    @Binding var volume: Double
    @Binding var fadeIn: Bool
    @Binding var snoozeMinutes: Int?
    let theme: CozyTheme
    @Environment(LanguageSetting.self) var language

    @State private var lastVolumeFeedbackTime = Date()
    @State private var feedbackPlayer = TonePlayer()

    var body: some View {
        VStack(spacing: 14) {
            // 라벨 입력
            VStack(alignment: .leading, spacing: 6) {
                Text(t(.alarmName))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.textSecondary)

                TextField(t(.alarmNamePlaceholder), text: Binding(
                    get: { label ?? "" },
                    set: { label = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(theme.subtleStroke, lineWidth: 1)
                )
            }

            // 볼륨 슬라이더
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(t(.volumeLabel))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.textSecondary)

                    Spacer()

                    Text("\(Int(volume * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.textPrimary)
                }

                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)

                    Slider(value: $volume, in: 0...1) { _ in
                        if Date().timeIntervalSince(lastVolumeFeedbackTime) > 0.25 {
                            lastVolumeFeedbackTime = Date()
                            feedbackPlayer.start(pattern: .morningHarp, volume: volume, fadeIn: false)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                feedbackPlayer.stop()
                            }
                        }
                    }
                    .tint(theme.accent)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding(14)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(theme.subtleStroke, lineWidth: 1)
            )

            // 토글 옵션들 (점진적 페이드인 & 스누즈)
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t(.gradualVolume))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(theme.textPrimary)
                        Text(t(.gradualVolumeDescription))
                            .font(.system(size: 10))
                            .foregroundStyle(theme.textTertiary)
                    }
                    Spacer()
                    CozyToggle(isOn: $fadeIn, accent: theme.accent)
                }

                Divider().opacity(theme.isLight ? 0.08 : 0.12)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t(.snoozeWithMinutes(9)))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(theme.textPrimary)
                        Text(t(.snoozeDescription))
                            .font(.system(size: 10))
                            .foregroundStyle(theme.textTertiary)
                    }
                    Spacer()
                    CozyToggle(isOn: Binding(
                        get: { snoozeMinutes != nil },
                        set: { snoozeMinutes = $0 ? 9 : nil }
                    ), accent: theme.accent)
                }
            }
            .padding(14)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(theme.subtleStroke, lineWidth: 1)
            )
        }
    }
}
