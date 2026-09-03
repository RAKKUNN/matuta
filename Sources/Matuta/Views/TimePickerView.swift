import SwiftUI
import AppKit
import MatutaCore

struct TimePickerView: View {
    @Binding var hour12: Int
    @Binding var minute: Int
    @Binding var isPM: Bool
    let theme: CozyTheme

    @FocusState private var focusedField: TimeFieldFocus?
    @State private var hourBuffer = TimeInputBuffer()
    @State private var minuteBuffer = TimeInputBuffer()

    enum TimeFieldFocus: Hashable {
        case hour
        case minute
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // 시/분 디지털 박스
                HStack(spacing: 8) {
                    // 시(Hour) 블록
                    timeUnitBlock(
                        value: hour12,
                        field: .hour,
                        onStep: { incrementHour($0) },
                        onSelect: {
                            focusedField = .hour
                            hourBuffer.reset()
                        }
                    )

                    Text(":")
                        .font(.system(size: 42, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(theme.textSecondary.opacity(0.6))
                        .offset(y: -2)

                    // 분(Minute) 블록
                    timeUnitBlock(
                        value: minute,
                        field: .minute,
                        onStep: { incrementMinute($0) },
                        onSelect: {
                            focusedField = .minute
                            minuteBuffer.reset()
                        }
                    )
                }
                .padding(8)
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(theme.subtleStroke, lineWidth: 1)
                )

                // AM / PM 토글 바
                VStack(spacing: 4) {
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            isPM = false
                        }
                    }) {
                        Text("AM")
                            .font(.system(size: 12, weight: !isPM ? .bold : .medium))
                            .frame(width: 46, height: 28)
                            .background(!isPM ? theme.accent : (theme.isLight ? Color.black.opacity(0.06) : Color.white.opacity(0.06)))
                            .foregroundStyle(!isPM ? Color.white : theme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            isPM = true
                        }
                    }) {
                        Text("PM")
                            .font(.system(size: 12, weight: isPM ? .bold : .medium))
                            .frame(width: 46, height: 28)
                            .background(isPM ? theme.accent : (theme.isLight ? Color.black.opacity(0.06) : Color.white.opacity(0.06)))
                            .foregroundStyle(isPM ? Color.white : theme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 퀵 타임 프리셋 칩
            HStack(spacing: 6) {
                quickTimeChip("06:30", h: 6, m: 30, pm: false)
                quickTimeChip("07:00", h: 7, m: 0, pm: false)
                quickTimeChip("07:30", h: 7, m: 30, pm: false)
                quickTimeChip("08:00", h: 8, m: 0, pm: false)
                quickTimeChip("08:30", h: 8, m: 30, pm: false)
            }
        }
    }

    private func timeUnitBlock(
        value: Int,
        field: TimeFieldFocus,
        onStep: @escaping (Int) -> Void,
        onSelect: @escaping () -> Void
    ) -> some View {
        let isFocused = focusedField == field

        return VStack(spacing: 2) {
            Button(action: { onStep(1) }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isFocused ? theme.accent : theme.textTertiary)
                    .frame(width: 60, height: 14)
            }
            .buttonStyle(.plain)

            // 숫자 디스플레이 (커서 없는 직관적인 타임피스 인터랙션)
            ZStack {
                Text(TimePickerLogic.formatTwoDigits(value))
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isFocused ? (theme.isLight ? theme.accent : Color.white) : theme.textSecondary)
                    .frame(width: 64, height: 48)
                    .background(isFocused ? theme.accent.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(isFocused ? theme.accent.opacity(0.4) : Color.clear, lineWidth: 1.5)
                    )

                // 스크롤 휠 및 클릭 이벤트 가로채기 (실시간 즉각 반영)
                ScrollClickOverlay(
                    onScroll: onStep,
                    onClick: onSelect
                )
                .frame(width: 64, height: 48)
            }
            .focusable()
            .focused($focusedField, equals: field)
            .onKeyPress(characters: .decimalDigits) { press in
                guard let char = press.characters.first else { return .ignored }
                handleDigitPress(char, for: field)
                return .handled
            }
            .onKeyPress(.upArrow) {
                onStep(1)
                return .handled
            }
            .onKeyPress(.downArrow) {
                onStep(-1)
                return .handled
            }

            Button(action: { onStep(-1) }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isFocused ? theme.accent : theme.textTertiary)
                    .frame(width: 60, height: 14)
            }
            .buttonStyle(.plain)
        }
    }

    private func handleDigitPress(_ char: Character, for field: TimeFieldFocus) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            switch field {
            case .hour:
                let result = hourBuffer.appendHourDigit(char, currentHour: hour12)
                hour12 = result.newHour
                if result.advance {
                    focusedField = .minute
                    minuteBuffer.reset()
                }
            case .minute:
                let result = minuteBuffer.appendMinuteDigit(char, currentMinute: minute)
                minute = result.newMinute
                if result.advance {
                    // 분까지 2자리 입력 완료 시 포커스 해제
                    focusedField = nil
                }
            }
        }
    }

    private func incrementHour(_ delta: Int) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            hour12 = TimePickerLogic.stepHour(hour12, delta: delta)
        }
    }

    private func incrementMinute(_ delta: Int) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            minute = TimePickerLogic.stepMinute(minute, delta: delta)
        }
    }

    private func quickTimeChip(_ label: String, h: Int, m: Int, pm: Bool) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                hour12 = h
                minute = m
                isPM = pm
            }
        }) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(theme.cardBackground)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(theme.subtleStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AppKit Scroll Wheel & Click Overlay (실시간 즉각 반응)

struct ScrollClickOverlay: NSViewRepresentable {
    let onScroll: (Int) -> Void
    let onClick: () -> Void

    func makeNSView(context: Context) -> ScrollClickNSView {
        let v = ScrollClickNSView()
        v.onScroll = onScroll
        v.onClick = onClick
        return v
    }

    func updateNSView(_ nsView: ScrollClickNSView, context: Context) {
        nsView.onScroll = onScroll
        nsView.onClick = onClick
    }
}

final class ScrollClickNSView: NSView {
    var onScroll: ((Int) -> Void)?
    var onClick: (() -> Void)?
    private var scrollAccumulator: CGFloat = 0

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func scrollWheel(with event: NSEvent) {
        let delta = event.scrollingDeltaY
        if event.hasPreciseScrollingDeltas {
            scrollAccumulator += delta
            let threshold: CGFloat = 8.0
            if scrollAccumulator >= threshold {
                onScroll?(1)
                scrollAccumulator = 0
            } else if scrollAccumulator <= -threshold {
                onScroll?(-1)
                scrollAccumulator = 0
            }
        } else {
            if delta > 0 {
                onScroll?(1)
            } else if delta < 0 {
                onScroll?(-1)
            }
        }
        if event.phase == .ended || event.phase == .cancelled {
            scrollAccumulator = 0
        }
    }
}
