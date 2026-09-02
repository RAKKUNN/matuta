import AppKit
import SwiftUI
import MatutaCore

final class NightstandWindow: NSWindow {
    var onDismiss: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        // 53 = ESC 키
        if event.keyCode == 53 {
            onDismiss?()
        } else {
            super.keyDown(with: event)
        }
    }
}

@MainActor
final class NightstandController {
    private var window: NightstandWindow?
    private let powerMatuta = SystemPowerMatuta()

    func show(nextFireDate: Date?, nextAlarm: Alarm?) {
        hide()

        guard let screen = NSScreen.main else { return }

        let win = NightstandWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.setFrame(screen.frame, display: true)
        win.level = .normal
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.isOpaque = true
        win.backgroundColor = .black
        win.hasShadow = false

        win.onDismiss = { [weak self] in
            self?.hide()
        }

        win.contentView = NSHostingView(
            rootView: NightstandView(
                nextFireDate: nextFireDate,
                nextAlarm: nextAlarm,
                onDismiss: { [weak self] in
                    self?.hide()
                }
            )
        )

        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        win.makeKey()
        self.window = win

        // 나이트스탠드 켜져 있는 동안 화면 켜짐 유지
        powerMatuta.acquireSleepAssertion(reason: "Matuta Nightstand Active")
    }

    func hide() {
        powerMatuta.releaseSleepAssertion()
        window?.orderOut(nil)
        window = nil
    }
}
