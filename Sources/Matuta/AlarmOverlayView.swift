import SwiftUI
import MatutaCore

struct AlarmOverlayView: View, Localizable {
    let alarm: Alarm
    let activeSourceText: LocalizedText?
    let onDismiss: () -> Void
    let onSnooze: () -> Void
    @Environment(LanguageSetting.self) var language

    @State private var now = Date()
    @State private var isDismissHovered = false
    @State private var isSnoozeHovered = false
    @State private var pulseAura = false
    @State private var isBreathing = false

    private var theme: CozyTheme {
        ThemeManager.shared.current
    }

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 포근한 새벽빛/모닥불 앰비언트 배경
            ambientBackground

            VStack(spacing: 0) {
                Spacer()

                // 대형 디지털 시계
                VStack(spacing: 8) {
                    Text(now, format: .dateTime.hour().minute().locale(language.locale))
                        .font(.system(size: 124, weight: .ultraLight, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.white)
                        .shadow(color: theme.accent.opacity(pulseAura ? 0.35 : 0.15), radius: 30, y: 10)

                    // 알람 라벨
                    Text(alarm.label ?? t(.pleasantMorning))
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .padding(.top, 4)

                    // 재생 소스 뱃지
                    sourcePillBadge
                        .padding(.top, 14)
                }

                Spacer()

                // 액션 버튼 영역 (스페이스바 및 마우스 클릭 지원)
                VStack(spacing: 16) {
                    // 메인 알람 끄기 버튼
                    Button(action: onDismiss) {
                        HStack(spacing: 12) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 19, weight: .semibold))

                            Text(t(.dismissAlarm))
                                .font(.system(size: 17, weight: .bold))

                            HStack(spacing: 3) {
                                Image(systemName: "space")
                                    .font(.system(size: 10, weight: .bold))
                                Text("SPACE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color.black.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .foregroundStyle(.black)
                        .frame(width: 260, height: 58)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
                        )
                        .shadow(color: theme.accent.opacity(isDismissHovered ? 0.45 : 0.20), radius: isDismissHovered ? 28 : 16, y: 6)
                        .scaleEffect(isDismissHovered ? 1.03 : 1.0)
                        .opacity(isBreathing ? 1.0 : 0.82)
                        .animation(
                            .easeInOut(duration: MotionEnvironment.duration(.affordanceBreath))
                                .repeatForever(autoreverses: true),
                            value: isBreathing
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { isDismissHovered = $0 }

                    // 스누즈 버튼 (스누즈 설정 시)
                    if let snooze = alarm.snoozeMinutes {
                        Button(action: onSnooze) {
                            HStack(spacing: 6) {
                                Image(systemName: "moon.zzz.fill")
                                    .font(.system(size: 12))
                                Text(t(.snoozeWithMinutes(snooze)))
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(Color.white.opacity(isSnoozeHovered ? 0.95 : 0.6))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(isSnoozeHovered ? 0.16 : 0.07))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .scaleEffect(isSnoozeHovered ? 1.02 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .onHover { isSnoozeHovered = $0 }
                    }

                    // 하단 오디오 가드 보호 뱃지
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 10))
                        Text(t(.builtInSpeakerProtected))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color.white.opacity(0.35))
                    .padding(.top, 8)
                }
                .padding(.bottom, 60)
            }
        }
        .onReceive(tick) { now = $0 }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                pulseAura = true
            }
            // Reduce Motion 이면 지속시간이 0 이라 사실상 정지 상태가 된다.
            isBreathing = true
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDismissHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSnoozeHovered)
    }

    private var ambientBackground: some View {
        ZStack {
            theme.baseBackground.ignoresSafeArea()

            RadialGradient(
                colors: [
                    theme.accent.opacity(pulseAura ? 0.35 : 0.20),
                    theme.cardBackground.opacity(pulseAura ? 0.25 : 0.15),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.35),
                startRadius: 40,
                endRadius: 700
            )
            .ignoresSafeArea()
            .blur(radius: 40)
        }
    }

    private var sourcePillBadge: some View {
        HStack(spacing: 7) {
            sourceIcon
                .font(.system(size: 11, weight: .semibold))

            Text(activeSourceText.map { t($0) } ?? defaultSourceText)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Color.white.opacity(0.9))
        .padding(.horizontal, 14)
        .padding(.vertical, 6.5)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
        )
    }

    @ViewBuilder
    private var sourceIcon: some View {
        switch alarm.source {
        case .builtIn:
            Image(systemName: "bell.fill").foregroundStyle(theme.accent)
        case .localFile:
            Image(systemName: "music.note").foregroundStyle(theme.accent)
        case .streamURL:
            Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(theme.accent)
        case .appleMusic:
            Image(systemName: "apple.logo").foregroundStyle(theme.accent)
        case .spotify:
            Image(systemName: "waveform").foregroundStyle(theme.accent)
        case .web:
            Image(systemName: "play.rectangle.fill").foregroundStyle(theme.accent)
        }
    }

    private var defaultSourceText: String {
        switch alarm.source {
        case .builtIn(let tone): tone.rawValue
        case .localFile: t(.localAudioFile)
        case .streamURL(let url): url.host ?? t(.streamRadio)
        case .appleMusic: "Apple Music"
        case .spotify: "Spotify"
        case .web(let url): url.host ?? t(.webAudio)
        }
    }
}
