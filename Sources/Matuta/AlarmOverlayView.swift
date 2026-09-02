import SwiftUI
import MatutaCore

struct AlarmOverlayView: View {
    let alarm: Alarm
    let activeSourceName: String
    let onDismiss: () -> Void
    let onSnooze: () -> Void

    @State private var now = Date()
    @State private var isDismissHovered = false
    @State private var isSnoozeHovered = false
    @State private var pulseAura = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 깊고 몽환적인 새벽빛 오라 배경
            ambientBackground

            VStack(spacing: 0) {
                Spacer()

                // 초대형 정밀 디지털 시계
                VStack(spacing: 8) {
                    Text(now, format: .dateTime.hour().minute())
                        .font(.system(size: 124, weight: .ultraLight, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.white)
                        .shadow(color: MatutaTheme.sunriseOrange.opacity(pulseAura ? 0.35 : 0.15), radius: 30, y: 10)

                    // 알람 라벨
                    Text(alarm.label?.uppercased() ?? "WAKE UP")
                        .font(.system(size: 18, weight: .medium, design: .default))
                        .tracking(3.5)
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

                            Text("알람 끄기")
                                .font(.system(size: 17, weight: .bold))
                                .tracking(0.5)

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
                        .shadow(color: Color.white.opacity(isDismissHovered ? 0.5 : 0.25), radius: isDismissHovered ? 28 : 16, y: 6)
                        .scaleEffect(isDismissHovered ? 1.03 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { isDismissHovered = $0 }

                    // 스누즈 버튼 (스누즈 설정 시)
                    if let snooze = alarm.snoozeMinutes {
                        Button(action: onSnooze) {
                            HStack(spacing: 6) {
                                Image(systemName: "moon.zzz.fill")
                                    .font(.system(size: 12))
                                Text("\(snooze)분 후 다시 알림 (스누즈)")
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
                        Text("내장 스피커 보호 출력 중")
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
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isDismissHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSnoozeHovered)
    }

    private var ambientBackground: some View {
        ZStack {
            MatutaTheme.baseBackground.ignoresSafeArea()

            RadialGradient(
                colors: [
                    MatutaTheme.sunriseOrange.opacity(pulseAura ? 0.35 : 0.20),
                    MatutaTheme.primaryAccent.opacity(pulseAura ? 0.25 : 0.15),
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

            Text(activeSourceName.isEmpty ? defaultSourceText : activeSourceName)
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.3)
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
            Image(systemName: "bell.fill").foregroundStyle(MatutaTheme.sunriseAmber)
        case .localFile:
            Image(systemName: "music.note").foregroundStyle(MatutaTheme.electricCyan)
        case .streamURL:
            Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(MatutaTheme.sunriseOrange)
        case .appleMusic:
            Image(systemName: "apple.logo").foregroundStyle(MatutaTheme.sunsetPink)
        case .spotify:
            Image(systemName: "waveform").foregroundStyle(MatutaTheme.neonGreen)
        case .web:
            Image(systemName: "play.rectangle.fill").foregroundStyle(.red)
        }
    }

    private var defaultSourceText: String {
        switch alarm.source {
        case .builtIn(let name): "Radar (\(name))"
        case .localFile: "Local Audio File"
        case .streamURL(let url): url.host ?? "Live Radio"
        case .appleMusic: "Apple Music"
        case .spotify: "Spotify"
        case .web(let url): url.host ?? "Web Stream"
        }
    }
}
