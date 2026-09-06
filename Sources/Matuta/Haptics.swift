import AppKit

/// 촉각 피드백. Force Touch 트랙패드에서만 실제로 느껴지고,
/// 그 외 기기에서는 조용히 아무 일도 하지 않는다.
@MainActor
enum Haptics {
    /// 되돌리기 어렵거나 무게가 있는 결정을 확인해 준다.
    ///
    /// 이 앱에서는 알람을 켜는 순간에만 쓴다. 모든 상호작용에 반응을 주면
    /// 아무것도 강조되지 않는다.
    static func commit() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic, performanceTime: .drawCompleted
        )
    }
}
