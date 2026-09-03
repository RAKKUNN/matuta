import SwiftUI
import AppKit
import MatutaCore

struct TimePickerView: View {
    @Binding var hour12: Int
    @Binding var minute: Int
    @Binding var isPM: Bool
    let theme: CozyTheme

    @State private var focusedField: TimeFieldFocus = .hour
    @State private var fieldRegistry = TimePickerFieldRegistry()

    enum TimeFieldFocus {
        case hour
        case minute
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // 시/분 디지털 박스
                HStack(spacing: 8) {
                    // 시(Hour) 블록 (스크롤 + 숫자 키보드 입력 + 화살표 키 + 클릭 증감)
                    timeUnitBlock(
                        value: $hour12,
                        isHour: true,
                        isFocused: focusedField == .hour,
                        onFocus: { focusedField = .hour },
                        onStep: { incrementHour($0) },
                        onAdvance: { fieldRegistry.focusMinute() }
                    )

                    Text(":")
                        .font(.system(size: 42, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(theme.textSecondary.opacity(0.6))
                        .offset(y: -2)

                    // 분(Minute) 블록 (스크롤 + 숫자 키보드 입력 + 화살표 키 + 클릭 증감)
                    timeUnitBlock(
                        value: $minute,
                        isHour: false,
                        isFocused: focusedField == .minute,
                        onFocus: { focusedField = .minute },
                        onStep: { incrementMinute($0) },
                        onAdvance: { fieldRegistry.clearFocus() }
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
        value: Binding<Int>,
        isHour: Bool,
        isFocused: Bool,
        onFocus: @escaping () -> Void,
        onStep: @escaping (Int) -> Void,
        onAdvance: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 2) {
            Button(action: { onStep(1) }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isFocused ? theme.accent : theme.textTertiary)
                    .frame(width: 60, height: 14)
            }
            .buttonStyle(.plain)

            TimeDigitFieldRepresentable(
                value: value,
                isHour: isHour,
                textColor: isFocused ? (theme.isLight ? NSColor(theme.accent) : NSColor.white) : NSColor(theme.textSecondary),
                registry: fieldRegistry,
                onFocus: onFocus,
                onStep: onStep,
                onAdvance: onAdvance
            )
            .frame(width: 64, height: 48)
            .background(isFocused ? theme.accent.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button(action: { onStep(-1) }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isFocused ? theme.accent : theme.textTertiary)
                    .frame(width: 60, height: 14)
            }
            .buttonStyle(.plain)
        }
        .background(
            ScrollWheelArea(onStep: onStep)
        )
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

// MARK: - AppKit Time Digit Input & Scroll Handling

@MainActor
final class TimePickerFieldRegistry {
    weak var hourField: TimeDigitNSTextField?
    weak var minuteField: TimeDigitNSTextField?

    func focusMinute() {
        if let mf = minuteField, let window = mf.window {
            window.makeFirstResponder(mf)
        }
    }

    func clearFocus() {
        if let hf = hourField, let window = hf.window {
            window.makeFirstResponder(nil)
        }
    }
}

struct TimeDigitFieldRepresentable: NSViewRepresentable {
    @Binding var value: Int
    let isHour: Bool
    let textColor: NSColor
    let registry: TimePickerFieldRegistry
    let onFocus: () -> Void
    let onStep: (Int) -> Void
    let onAdvance: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> TimeDigitNSTextField {
        let tf = TimeDigitNSTextField()
        tf.delegate = context.coordinator
        tf.isHour = isHour
        tf.onStep = onStep
        tf.onAdvance = onAdvance
        tf.onFocus = onFocus
        tf.font = NSFont.monospacedDigitSystemFont(ofSize: 42, weight: .light)
        tf.alignment = .center
        tf.isBordered = false
        tf.drawsBackground = false
        tf.focusRingType = .none
        tf.textColor = textColor
        tf.stringValue = TimePickerLogic.formatTwoDigits(value)

        if isHour {
            registry.hourField = tf
        } else {
            registry.minuteField = tf
        }

        return tf
    }

    func updateNSView(_ nsView: TimeDigitNSTextField, context: Context) {
        context.coordinator.parent = self
        nsView.isHour = isHour
        nsView.textColor = textColor
        nsView.onStep = onStep
        nsView.onAdvance = onAdvance
        nsView.onFocus = onFocus

        // 활성 커서 입력 중이 아닐 때만 외부 상태 변경 반영
        if nsView.currentEditor() == nil {
            let formatted = TimePickerLogic.formatTwoDigits(value)
            if nsView.stringValue != formatted {
                nsView.stringValue = formatted
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TimeDigitFieldRepresentable

        init(_ parent: TimeDigitFieldRepresentable) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            parent.onFocus()
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            let text = tf.stringValue

            if parent.isHour {
                if let parsed = TimePickerLogic.parseHourInput(text) {
                    parent.value = parsed.value
                    if parsed.shouldAdvance {
                        parent.onAdvance()
                    }
                }
            } else {
                if let parsed = TimePickerLogic.parseMinuteInput(text) {
                    parent.value = parsed.value
                    if parsed.shouldAdvance {
                        parent.onAdvance()
                    }
                }
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            tf.stringValue = TimePickerLogic.formatTwoDigits(parent.value)
        }
    }
}

final class TimeDigitNSTextField: NSTextField {
    var isHour: Bool = false
    var onStep: ((Int) -> Void)?
    var onAdvance: (() -> Void)?
    var onFocus: (() -> Void)?

    private var scrollAccumulator: CGFloat = 0

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()
        if success {
            onFocus?()
            DispatchQueue.main.async { [weak self] in
                self?.selectText(nil)
            }
        }
        return success
    }

    override func scrollWheel(with event: NSEvent) {
        let delta = event.scrollingDeltaY
        if event.hasPreciseScrollingDeltas {
            scrollAccumulator += delta
            let threshold: CGFloat = 8.0
            if scrollAccumulator >= threshold {
                onStep?(1)
                scrollAccumulator = 0
            } else if scrollAccumulator <= -threshold {
                onStep?(-1)
                scrollAccumulator = 0
            }
        } else {
            if delta > 0 {
                onStep?(1)
            } else if delta < 0 {
                onStep?(-1)
            }
        }
        if event.phase == .ended || event.phase == .cancelled {
            scrollAccumulator = 0
        }
    }

    override func keyDown(with event: NSEvent) {
        // 위쪽 화살표 키: 126
        if event.keyCode == 126 {
            onStep?(1)
            return
        }
        // 아래쪽 화살표 키: 125
        if event.keyCode == 125 {
            onStep?(-1)
            return
        }
        // Tab 키: 48
        if event.keyCode == 48 {
            onAdvance?()
            return
        }
        // Return / Enter 키: 36
        if event.keyCode == 36 {
            window?.makeFirstResponder(nil)
            return
        }
        super.keyDown(with: event)
    }
}

// MARK: - Unit Block Scroll Wheel Area

struct ScrollWheelArea: NSViewRepresentable {
    let onStep: (Int) -> Void

    func makeNSView(context: Context) -> ScrollWheelNSView {
        let v = ScrollWheelNSView()
        v.onStep = onStep
        return v
    }

    func updateNSView(_ nsView: ScrollWheelNSView, context: Context) {
        nsView.onStep = onStep
    }
}

final class ScrollWheelNSView: NSView {
    var onStep: ((Int) -> Void)?
    private var scrollAccumulator: CGFloat = 0

    override func scrollWheel(with event: NSEvent) {
        let delta = event.scrollingDeltaY
        if event.hasPreciseScrollingDeltas {
            scrollAccumulator += delta
            let threshold: CGFloat = 8.0
            if scrollAccumulator >= threshold {
                onStep?(1)
                scrollAccumulator = 0
            } else if scrollAccumulator <= -threshold {
                onStep?(-1)
                scrollAccumulator = 0
            }
        } else {
            if delta > 0 {
                onStep?(1)
            } else if delta < 0 {
                onStep?(-1)
            }
        }
        if event.phase == .ended || event.phase == .cancelled {
            scrollAccumulator = 0
        }
    }
}
