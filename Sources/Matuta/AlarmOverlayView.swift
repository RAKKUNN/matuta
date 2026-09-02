import SwiftUI
import MatutaCore

struct AlarmOverlayView: View {
    let alarm: Alarm
    let onSnooze: () -> Void

    @State private var now = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.11, green: 0.23, blue: 0.36), .black],
                center: .init(x: 0.5, y: 0.25),
                startRadius: 0,
                endRadius: 900
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(now, format: .dateTime.hour().minute())
                    .font(.system(size: 108, weight: .thin))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(alarm.label ?? "일어날 시간")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, 10)

                Text("🔔 Radar")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 6)

                Text("space")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.14))
                            .strokeBorder(.white.opacity(0.3))
                    )
                    .padding(.top, 46)

                Text("스페이스바를 눌러 끄기")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 9)

                if alarm.snoozeMinutes != nil {
                    // 마우스로만 누를 수 있다. 키보드 포커스를 주지 않는다.
                    Button("스누즈 \(alarm.snoozeMinutes!)분") {
                        onSnooze()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 6)
                    .overlay(
                        Capsule().stroke(.white.opacity(0.2))
                    )
                    .focusable(false)
                    .padding(.top, 34)
                }
            }
        }
        .onReceive(tick) { now = $0 }
    }
}
