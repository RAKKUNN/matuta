import SwiftUI
import MatutaCore

/// 메뉴바에 다음 알람 시각만 조용히 띄운다.
///
/// App 의 계산 프로퍼티였던 것을 뷰로 옮겼다. App 안에 두면 모델을 읽을 때마다
/// 씬 그래프 갱신 경로에서 동적 액터 검사가 생긴다.
struct MenuBarLabelView: View {
    var body: some View {
        let model = AlarmListModel.shared
        let language = LanguageSetting.shared

        if model.firing != nil {
            HStack(spacing: 3) {
                Image(systemName: "bell.and.waveform.fill")
                Text(Localizer.string(.alarmFiring, language.resolved))
            }
        } else if let next = model.nextFireDate {
            HStack(spacing: 3) {
                Image(systemName: "alarm.fill")
                Text(next.formatted(.dateTime.hour().minute().locale(language.locale)))
            }
        } else {
            Image(systemName: "alarm")
        }
    }
}
