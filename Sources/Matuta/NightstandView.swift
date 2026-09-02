import SwiftUI
import MatutaCore

struct NightstandView: View {
    let nextFireDate: Date?
    let nextAlarm: Alarm?
    let onDismiss: () -> Void

    @State private var now = Date()
    @State private var report: PreflightReport?
    @State private var isControlsVisible: Bool = true
    @State private var idleTimer: Timer?
    @State private var isCloseHovered: Bool = false
    @State private var candleFlicker: Bool = false
    @State private var pixelShiftOffset: CGSize = .zero

    private var theme: CozyTheme {
        ThemeManager.shared.current
    }

    private let engine = PreflightEngine()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 저자극 딥 앰비언트 배경
            theme.baseBackground.ignoresSafeArea()

            // 부드러운 촛불/모닥불 앰비언트 글로우
            RadialGradient(
                colors: [
                    theme.accent.opacity(candleFlicker ? 0.18 : 0.10),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 550
            )
            .ignoresSafeArea()
            .blur(radius: 60)

            VStack(spacing: 0) {
                // 상단 컨트롤 바 (마우스 조작 시 페이드인)
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: theme.themeIcon)
                            .font(.system(size: 13))
                            .foregroundStyle(theme.accent)
                        Text(theme.rawValue.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        HStack(spacing: 6) {
                            Text("ESC")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color.white.opacity(isCloseHovered ? 0.95 : 0.45))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(isCloseHovered ? 0.12 : 0.05))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .onHover { isCloseHovered = $0 }
                }
                .padding(.horizontal, 36)
                .padding(.top, 28)
                .opacity(isControlsVisible ? 1 : 0)

                Spacer()

                // 대형 저자극 디지털 시계 (OLED 번인 방지 픽셀 시프트 적용)
                VStack(spacing: 12) {
                    Text(now, format: .dateTime.hour().minute())
                        .font(.system(size: 136, weight: .ultraLight, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.white.opacity(0.92))
                        .shadow(color: theme.accent.opacity(candleFlicker ? 0.25 : 0.12), radius: 30, y: 0)

                    // 다음 알람 및 카운트다운
                    if let next = nextFireDate {
                        HStack(spacing: 8) {
                            Image(systemName: "alarm.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(theme.accent)

                            Text("다음 알람: \(next.formatted(date: .omitted, time: .shortened))")
                                .font(.system(size: 15, weight: .medium))

                            Text("·")
                                .foregroundStyle(Color.white.opacity(0.3))

                            Text(countdownText(to: next))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.7))
                        }
                        .foregroundStyle(Color.white.opacity(0.85))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.05))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                        )
                    } else {
                        Text("켜진 알람이 없습니다")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                }
                .offset(pixelShiftOffset)

                Spacer()

                // 하단 3중 방어선 상태 표시줄
                HStack(spacing: 18) {
                    guardItem(icon: "speaker.wave.2.fill", label: "내장 스피커 보호", color: theme.accent)
                    guardItem(icon: "bolt.fill", label: "절전 깨우기 예약됨", color: theme.accent)
                    guardItem(icon: "shield.fill", label: "AudioGuard 활성", color: theme.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.07), lineWidth: 1))
                )
                .padding(.bottom, 40)
                .opacity(isControlsVisible ? 1 : 0.25)
            }
        }
        .onReceive(tick) { time in
            now = time
            updatePixelShift(at: time)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                candleFlicker = true
            }
        }
        .task {
            report = await engine.evaluate(alarm: nextAlarm)
        }
        .onContinuousHover { _ in
            showControlsWithTimeout()
        }
        .animation(.easeInOut(duration: 0.35), value: isControlsVisible)
        .animation(.easeInOut(duration: 0.2), value: isCloseHovered)
    }

    private func guardItem(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))
        }
    }

    private func showControlsWithTimeout() {
        isControlsVisible = true
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { _ in
            MainActor.assumeIsolated {
                isControlsVisible = false
            }
        }
    }

    private func updatePixelShift(at date: Date) {
        let minute = Calendar.current.component(.minute, from: date)
        let angle = Double(minute) * (Double.pi / 30.0)
        let shiftX = cos(angle) * 4.0
        let shiftY = sin(angle) * 3.0
        withAnimation(.easeInOut(duration: 2.0)) {
            self.pixelShiftOffset = CGSize(width: shiftX, height: shiftY)
        }
    }

    private func countdownText(to date: Date) -> String {
        let diff = max(0, Int(date.timeIntervalSince(now)))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분 후 울림"
        } else {
            return "\(minutes)분 후 울림"
        }
    }
}
