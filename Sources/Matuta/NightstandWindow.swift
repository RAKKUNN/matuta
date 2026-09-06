import AppKit
import SwiftUI
import MatutaCore

final class NightstandWindow: NSWindow {
    var onDismiss: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            onDismiss?()
        } else {
            super.keyDown(with: event)
        }
    }
}

@MainActor
final class NightstandController {
    private var window: NightstandWindow?
    private let wakeScheduler = SystemWakeScheduler()

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
        // .normal이면 메뉴 막대와 Dock이 위에 남는다. 침대 옆 시계인데
        // 화면 위아래가 빛나면 목적이 반감된다. 알람 오버레이와 같은 레벨을 쓴다.
        win.level = .screenSaver
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
            .environment(LanguageSetting.shared)
        )

        win.alphaValue = 0
        win.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = MotionEnvironment.duration(.nightstandAppear)
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            win.animator().alphaValue = 1
        }
        NSApp.activate(ignoringOtherApps: true)
        win.makeKey()
        self.window = win

        // 나이트스탠드 켜져 있는 동안 화면 켜짐 유지
        wakeScheduler.acquireSleepAssertion(reason: "Matuta Nightstand Active")
    }

    func hide() {
        wakeScheduler.releaseSleepAssertion()
        guard let closing = window else { return }
        window = nil

        NSAnimationContext.runAnimationGroup { context in
            context.duration = MotionEnvironment.duration(.nightstandDismiss)
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            closing.animator().alphaValue = 0
        } completionHandler: {
            MainActor.assumeIsolated {
                closing.orderOut(nil)
            }
        }
    }
}
