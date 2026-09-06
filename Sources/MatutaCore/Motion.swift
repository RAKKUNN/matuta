import Foundation

/// 앱의 모션 어휘. 지속시간을 뷰마다 흩뿌리지 않고 여기 이름을 붙여 모은다.
///
/// 판정(Reduce Motion 이면 0)은 순수 함수이므로 테스트가 지킨다.
/// 시스템 설정을 읽는 일은 앱 레이어(`MotionEnvironment`)가 한다.
public enum Motion {

    public enum Role: CaseIterable, Sendable {
        /// 알람이 울리며 전체화면이 나타난다. 이 앱에서 가장 조심스러워야 할 순간.
        case alarmAppear
        /// 스페이스바로 알람을 껐다. 확인은 주되 기다리게 하지 않는다.
        case alarmDismiss
        /// 알람 추가·삭제·시각 변경에 따른 목록 재배치.
        case listChange
        /// "SPACE" 어포던스의 느린 호흡.
        case affordanceBreath
        case nightstandAppear
        case nightstandDismiss
    }

    /// 무언가를 끄는 모션의 상한. 이 위로 올라가면 사용자가 기다리게 된다.
    public static let dismissCeiling: Double = 0.3

    public static func duration(_ role: Role, reduceMotion: Bool) -> Double {
        guard !reduceMotion else { return 0 }

        switch role {
        case .alarmAppear:        return 0.45   // 소리 페이드인과 성격을 맞춘다
        case .alarmDismiss:       return 0.22
        case .listChange:         return 0.28
        case .affordanceBreath:   return 2.0    // 호흡. 빠르면 초조해 보인다
        case .nightstandAppear:   return 0.40
        case .nightstandDismiss:  return 0.22
        }
    }
}
