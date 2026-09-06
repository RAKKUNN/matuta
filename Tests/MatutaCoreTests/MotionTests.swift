import Testing
import Foundation
@testable import MatutaCore

@Test("Reduce Motion 이 켜지면 모든 모션이 즉시 끝난다")
func reduceMotionCollapsesEverything() {
    for role in Motion.Role.allCases {
        #expect(Motion.duration(role, reduceMotion: true) == 0)
    }
}

@Test("평소에는 모든 역할이 0보다 큰 지속시간을 갖는다")
func normalMotionHasDuration() {
    for role in Motion.Role.allCases {
        #expect(Motion.duration(role, reduceMotion: false) > 0)
    }
}

@Test("알람을 끄는 모션은 상한을 넘지 않는다")
func dismissMotionStaysSnappy() {
    // 반쯤 잠든 사람이 애니메이션을 기다리게 두지 않는다.
    // 이 상한은 취향이 아니라 제품 규칙이다.
    #expect(Motion.duration(.alarmDismiss, reduceMotion: false) <= Motion.dismissCeiling)
    #expect(Motion.duration(.nightstandDismiss, reduceMotion: false) <= Motion.dismissCeiling)
}

@Test("알람 등장은 해제보다 느리다")
func appearIsGentlerThanDismiss() {
    // 등장은 부드럽게, 해제는 즉각. 성격이 반대다.
    #expect(Motion.duration(.alarmAppear, reduceMotion: false)
            > Motion.duration(.alarmDismiss, reduceMotion: false))
}

@Test("어포던스 호흡은 눈에 거슬리지 않을 만큼 느리다")
func breathIsSlow() {
    #expect(Motion.duration(.affordanceBreath, reduceMotion: false) >= 1.5)
}
