import AppKit
import SwiftUI
import MatutaCore

/// 전체화면을 점유하는 알람 창.
///
/// 키 처리 규칙: **스페이스바만 받고 나머지는 전부 삼킨다.** `super.keyDown`을
/// 호출하지 않으므로 다른 키를 눌러도 아무 일이 없고 비프음도 안 난다.
/// 스누즈에 키보드로 도달할 수 없게 만드는 것이 이 규칙의 목적이다.
final class AlarmOverlayWindow: NSWindow {
    var onDismiss: (() -> Void)?
    var presentedAt: Date = Date()

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        // 49 = 스페이스바
        if event.keyCode == 49 {
            // 알람이 뜨는 순간 다른 앱에서 타이핑 중이던 스페이스바로 즉시 꺼지는 것 방지 (0.5초 쿨다운)
            guard Date().timeIntervalSince(presentedAt) >= 0.5 else { return }
            onDismiss?()
        }
        // 그 외 키는 의도적으로 무시한다. super를 부르지 않는다.
    }
}

/// 연결된 모든 화면에 오버레이를 띄운다.
@MainActor
final class AlarmOverlayController {
    private var windows: [AlarmOverlayWindow] = []

    func show(
        alarm: Alarm,
        playbackChain: PlaybackChain,
        onDismiss: @escaping () -> Void,
        onSnooze: @escaping () -> Void
    ) {
        hide()

        for screen in NSScreen.screens {
            let window = AlarmOverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.setFrame(screen.frame, display: true)
            window.onDismiss = onDismiss
            window.presentedAt = Date()
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.isOpaque = true
            window.backgroundColor = .black
            window.hasShadow = false
            window.contentView = NSHostingView(
                rootView: AlarmOverlayView(
                    alarm: alarm,
                    activeSourceText: playbackChain.activeSourceText,
                    onDismiss: onDismiss,
                    onSnooze: onSnooze
                )
                .environment(LanguageSetting.shared)
            )
            // 소리는 이미 나고 있다. 화면만 서서히 덮는다.
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = MotionEnvironment.duration(.alarmAppear)
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 1
            }
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
        // 첫 번째 창이 키 창이어야 스페이스바가 들어온다.
        windows.first?.makeKey()
    }

    /// 외부 앱이 그래도 앞으로 나온 경우를 대비한 보험.
    /// 떠 있는 오버레이가 없으면 아무 일도 하지 않는다.
    func refocus() {
        guard let first = windows.first else { return }
        NSApp.activate(ignoringOtherApps: true)
        first.makeKeyAndOrderFront(nil)
    }

    func hide(completion: (@MainActor @Sendable () -> Void)? = nil) {
        let closing = windows
        windows.removeAll()

        guard !closing.isEmpty else {
            completion?()
            return
        }

        let duration = MotionEnvironment.duration(.alarmDismiss)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            for window in closing {
                window.animator().alphaValue = 0
            }
        } completionHandler: {
            MainActor.assumeIsolated {
                for window in closing {
                    window.orderOut(nil)
                }
                completion?()
            }
        }
    }
}
