import Foundation

/// 타이머를 갈아끼울 수 있게 하는 통로. 테스트는 시간이 흐르길 기다리지 않는다.
@MainActor
public protocol AlarmTimer: AnyObject {
    func schedule(at date: Date, handler: @escaping @MainActor () -> Void)
    func cancel()
}

@MainActor
public final class SystemAlarmTimer: AlarmTimer {
    private var timer: Timer?

    public init() {}

    public func schedule(at date: Date, handler: @escaping @MainActor () -> Void) {
        cancel()
        // 이미 지난 시각이면 즉시 발화한다.
        let interval = max(0, date.timeIntervalSinceNow)
        let timer = Timer(timeInterval: interval, repeats: false) { _ in
            MainActor.assumeIsolated { handler() }
        }
        // .common 모드로 넣어야 메뉴를 열어둔 동안에도 발화한다.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func cancel() {
        timer?.invalidate()
        timer = nil
    }
}
