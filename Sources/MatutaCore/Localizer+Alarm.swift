import Foundation

extension Localizer {
    static func stringForAlarm(_ text: LocalizedText, _ language: ResolvedLanguage) -> String {
        switch text {
        case .alarmListTitle:
            switch language {
            case .korean: return "알람"
            case .english: return "Alarms"
            }

        case .addAlarm:
            switch language {
            case .korean: return "알람 추가"
            case .english: return "Add Alarm"
            }

        case .editAlarm:
            switch language {
            case .korean: return "알람 편집"
            case .english: return "Edit Alarm"
            }

        case .newAlarm:
            switch language {
            case .korean: return "새 알람"
            case .english: return "New Alarm"
            }

        case .cancel:
            switch language {
            case .korean: return "취소"
            case .english: return "Cancel"
            }

        case .save:
            switch language {
            case .korean: return "저장"
            case .english: return "Save"
            }

        case .delete:
            switch language {
            case .korean: return "삭제"
            case .english: return "Delete"
            }

        case .duplicate:
            switch language {
            case .korean: return "복제"
            case .english: return "Duplicate"
            }

        case .edit:
            switch language {
            case .korean: return "편집"
            case .english: return "Edit"
            }

        case .noAlarms:
            switch language {
            case .korean: return "설정된 알람 없음"
            case .english: return "No Alarms Set"
            }

        case .noActiveAlarms:
            switch language {
            case .korean: return "켜진 알람이 없습니다"
            case .english: return "No Active Alarms"
            }

        case .alarmCount(let count):
            switch language {
            case .korean: return "\(count)개의 알람"
            case .english: return "\(count) Alarm\(count == 1 ? "" : "s")"
            }

        case .speakerStatus(let volume):
            switch language {
            case .korean: return "스피커 · 볼륨 \(volume)%"
            case .english: return "Speaker · Volume \(volume)%"
            }

        case .everyday:
            switch language {
            case .korean: return "매일"
            case .english: return "Every day"
            }

        case .weekdays:
            switch language {
            case .korean: return "주중"
            case .english: return "Weekdays"
            }

        case .weekends:
            switch language {
            case .korean: return "주말"
            case .english: return "Weekends"
            }

        case .once:
            switch language {
            case .korean: return "1회성"
            case .english: return "Once"
            }

        case .snoozing:
            switch language {
            case .korean: return "스누즈 중"
            case .english: return "Snoozing"
            }

        case .repeatLabel:
            switch language {
            case .korean: return "반복"
            case .english: return "Repeat"
            }

        case .soundLabel:
            switch language {
            case .korean: return "사운드"
            case .english: return "Sound"
            }

        case .optionsLabel:
            switch language {
            case .korean: return "옵션"
            case .english: return "Options"
            }

        case .volumeLabel:
            switch language {
            case .korean: return "볼륨"
            case .english: return "Volume"
            }

        case .alarmName:
            switch language {
            case .korean: return "라벨"
            case .english: return "Label"
            }

        case .alarmNamePlaceholder:
            switch language {
            case .korean: return "알람 이름 (예: 상쾌한 아침, 커피 타임, 출근)"
            case .english: return "Alarm label (e.g. Wake up, Coffee time)"
            }

        case .snooze:
            switch language {
            case .korean: return "스누즈"
            case .english: return "Snooze"
            }

        case .snoozeDescription:
            switch language {
            case .korean: return "알람 울릴 때 9분 뒤 다시 울림 허용"
            case .english: return "Allows ringing again in 9 minutes"
            }

        case .minutes(let m):
            switch language {
            case .korean: return "\(m)분"
            case .english: return "\(m) min"
            }

        case .gradualVolume:
            switch language {
            case .korean: return "서서히 커지기 (점진적 페이드인)"
            case .english: return "Gradual Volume"
            }

        case .gradualVolumeDescription:
            switch language {
            case .korean: return "낮은 볼륨에서 설정 볼륨까지 30초간 부드럽게 상승"
            case .english: return "Gently ramps up from low volume over 30s"
            }

        case .nextAlarm:
            switch language {
            case .korean: return "다음 알람"
            case .english: return "Next Alarm"
            }

        case .nextAlarmAt(let time):
            switch language {
            case .korean: return "다음 알람: \(time)"
            case .english: return "Next Alarm: \(time)"
            }

        default:
            return ""
        }
    }
}
