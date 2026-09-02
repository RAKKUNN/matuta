import AppKit
import SwiftUI
import MatutaCore

/// 전체화면을 점유하는 알람 창.
///
/// 키 처리 규칙: **스페이스바만 받고 나머지는 전부 삼킨다.** `super.keyDown`을
/// 호출하지 않으므로 다른 키를 눌러도 아무 일이 없고 비프음도 안 난다.
/// 스누즈에 키보드로 도달할 수 없게 만드는 것이 이 규칙의 목적이다.
final class AlarmOverlayWindow: NSWindow {
    private let onDismiss: () -> Void

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(screen: NSScreen, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = true
        backgroundColor = .black
        hasShadow = false
    }

    override func keyDown(with event: NSEvent) {
        // 49 = 스페이스바
        if event.keyCode == 49 {
            onDismiss()
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
        onDismiss: @escaping () -> Void,
        onSnooze: @escaping () -> Void
    ) {
        hide()

        for screen in NSScreen.screens {
            let window = AlarmOverlayWindow(screen: screen, onDismiss: onDismiss)
            window.contentView = NSHostingView(
                rootView: AlarmOverlayView(alarm: alarm, onSnooze: onSnooze)
            )
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
        // 첫 번째 창이 키 창이어야 스페이스바가 들어온다.
        windows.first?.makeKey()
    }

    func hide() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }
}
