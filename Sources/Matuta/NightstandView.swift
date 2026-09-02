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

    private let engine = PreflightEngine()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 눈부심 없는 깊은 미드나이트 배경
            Color(red: 0.03, green: 0.03, blue: 0.05).ignoresSafeArea()

            VStack(spacing: 0) {
                // 상단 컨트롤 바 (마우스 움직일 때만 페이드인)
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.stars.fill")
                            .foregroundStyle(.yellow.opacity(0.8))
                        Text("나이트스탠드")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(isCloseHovered ? 0.9 : 0.4))
                    }
                    .buttonStyle(.plain)
                    .onHover { isCloseHovered = $0 }
                }
                .padding(.horizontal, 30)
                .padding(.top, 24)
                .opacity(isControlsVisible ? 1 : 0)

                Spacer()

                // 초대형 미니멀 디지털 시계
                VStack(spacing: 12) {
                    Text(now, format: .dateTime.hour().minute())
                        .font(.system(size: 128, weight: .ultraLight, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.white.opacity(0.92))

                    // 다음 알람 및 카운트다운
                    if let next = nextFireDate {
                        Text("다음 알람: \(next.formatted(date: .omitted, time: .shortened)) · \(countdownText(to: next))")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(.white.opacity(0.65))
                    } else {
                        Text("켜진 알람이 없습니다")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }

                Spacer()

                // 하단 프리플라이트 상태 배지
                if let report = report {
                    HStack(spacing: 8) {
                        Image(systemName: report.isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(report.isReady ? .green : .orange)
                        Text(report.statusText)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                    )
                    .padding(.bottom, 36)
                    .opacity(isControlsVisible ? 1 : 0.3)
                }
            }
        }
        .onReceive(tick) { now = $0 }
        .task {
            report = await engine.evaluate(alarm: nextAlarm)
        }
        .onContinuousHover { _ in
            showControlsWithTimeout()
        }
        .animation(.easeInOut(duration: 0.3), value: isControlsVisible)
        .animation(.easeInOut(duration: 0.2), value: isCloseHovered)
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
