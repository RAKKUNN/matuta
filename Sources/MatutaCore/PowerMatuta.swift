import Foundation

public protocol PowerManagement: Sendable {
    /// 다음 알람 시각에 맞춰 Mac 절전 자동 깨우기를 예약한다.
    @discardableResult
    func scheduleWake(at date: Date) -> Bool

    /// 예약된 절전 깨우기를 취소한다.
    func cancelWake()

    /// 알람 발화 중 화면/시스템 절전 방지 assertion을 획득한다.
    func acquireSleepAssertion(reason: String)

    /// 획득한 절전 방지 assertion을 해제한다.
    func releaseSleepAssertion()
}
