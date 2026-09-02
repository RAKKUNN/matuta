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
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 미니멀하고 몽환적인 새벽빛 배경
            backgroundView

            VStack(spacing: 0) {
                Spacer()

                // 현재 시각 (미니멀하고 세련된 대형 타이포그래피)
                Text(now, format: .dateTime.hour().minute())
                    .font(.system(size: 116, weight: .ultraLight, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

                // 알람 라벨
                Text(alarm.label ?? "좋은 아침이에요")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 4)

                // 재생 소스 뱃지 (글래스모피즘 칩)
                sourceBadgeView
                    .padding(.top, 14)

                Spacer()

                // 액션 버튼 영역 (마우스 클릭 & 스페이스바 완벽 지원)
                VStack(spacing: 16) {
                    // 메인 알람 끄기 버튼 (마우스 클릭 가능 대형 버튼)
                    Button(action: onDismiss) {
                        HStack(spacing: 10) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("알람 끄기")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Space")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .foregroundStyle(.black)
                        .frame(width: 240, height: 56)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: Color.white.opacity(isDismissHovered ? 0.4 : 0.2), radius: isDismissHovered ? 25 : 15, y: 5)
                        .scaleEffect(isDismissHovered ? 1.03 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { isDismissHovered = $0 }

                    // 스누즈 버튼 (설정된 경우)
                    if let snooze = alarm.snoozeMinutes {
                        Button(action: onSnooze) {
                            HStack(spacing: 6) {
                                Image(systemName: "moon.zzz.fill")
                                    .font(.caption)
                                Text("\(snooze)분 후 다시 알림")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(.white.opacity(isSnoozeHovered ? 0.95 : 0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(isSnoozeHovered ? 0.15 : 0.08))
                            .clipShape(Capsule())
                            .scaleEffect(isSnoozeHovered ? 1.02 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .onHover { isSnoozeHovered = $0 }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onReceive(tick) { now = $0 }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDismissHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSnoozeHovered)
    }

    private var backgroundView: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.15, green: 0.25, blue: 0.45).opacity(0.7),
                    Color(red: 0.08, green: 0.09, blue: 0.18).opacity(0.4),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.35),
                startRadius: 50,
                endRadius: 650
            )
            .ignoresSafeArea()
        }
    }

    private var sourceBadgeView: some View {
        HStack(spacing: 6) {
            sourceIcon
                .font(.caption)
            Text(activeSourceName.isEmpty ? fallbackSourceName : activeSourceName)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        )
    }

    @ViewBuilder
    private var sourceIcon: some View {
        switch alarm.source {
        case .builtIn:
            Image(systemName: "bell.fill").foregroundStyle(.yellow)
        case .localFile:
            Image(systemName: "music.note").foregroundStyle(.cyan)
        case .streamURL:
            Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(.orange)
        case .appleMusic:
            Image(systemName: "applelogo").foregroundStyle(.pink)
        case .spotify:
            Image(systemName: "waveform.circle.fill").foregroundStyle(.green)
        case .web:
            Image(systemName: "play.rectangle.fill").foregroundStyle(.red)
        }
    }

    private var fallbackSourceName: String {
        switch alarm.source {
        case .builtIn(let name): "🔔 \(name)"
        case .localFile: "🎵 로컬 음악"
        case .streamURL(let url): "📻 \(url.host ?? "라디오")"
        case .appleMusic: "🍎 Apple Music"
        case .spotify: "🟢 Spotify"
        case .web(let url): "🌐 \(url.host ?? "웹")"
        }
    }
}
