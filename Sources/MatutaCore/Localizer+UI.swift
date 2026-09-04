import Foundation

extension Localizer {
    static func stringForUI(_ text: LocalizedText, _ language: ResolvedLanguage) -> String {
        switch text {
        case .am:
            return "AM"

        case .pm:
            return "PM"

        case .sundayShort:
            switch language {
            case .korean: return "일"
            case .english: return "Sun"
            }

        case .mondayShort:
            switch language {
            case .korean: return "월"
            case .english: return "Mon"
            }

        case .tuesdayShort:
            switch language {
            case .korean: return "화"
            case .english: return "Tue"
            }

        case .wednesdayShort:
            switch language {
            case .korean: return "수"
            case .english: return "Wed"
            }

        case .thursdayShort:
            switch language {
            case .korean: return "목"
            case .english: return "Thu"
            }

        case .fridayShort:
            switch language {
            case .korean: return "금"
            case .english: return "Fri"
            }

        case .saturdayShort:
            switch language {
            case .korean: return "토"
            case .english: return "Sat"
            }

        case .alarmCountdownHoursMinutes(let hours, let minutes):
            switch language {
            case .korean: return "\(hours)시간 \(minutes)분 후 울림"
            case .english: return "Rings in \(hours)h \(minutes)m"
            }

        case .alarmCountdownMinutes(let minutes):
            switch language {
            case .korean: return "\(minutes)분 후 울림"
            case .english: return "Rings in \(minutes)m"
            }

        case .alarmCountdownSoon:
            switch language {
            case .korean: return "잠시 후 울림"
            case .english: return "Rings soon"
            }

        case .remaining(let time):
            switch language {
            case .korean: return "\(time) 남음"
            case .english: return "\(time) left"
            }

        case .dismissAlarm:
            switch language {
            case .korean: return "알람 끄기"
            case .english: return "Dismiss"
            }

        case .dismissAlarmSpace:
            switch language {
            case .korean: return "알람 끄기 (Space)"
            case .english: return "Dismiss (Space)"
            }

        case .snoozeWithMinutes(let m):
            switch language {
            case .korean: return "스누즈 (\(m)분)"
            case .english: return "Snooze (\(m)m)"
            }

        case .pressSpaceToDismiss:
            switch language {
            case .korean: return "Space 키를 누르면 꺼집니다"
            case .english: return "Press Space to dismiss"
            }

        case .alarmFiring:
            switch language {
            case .korean: return "알람 울림"
            case .english: return "Alarm Firing"
            }

        case .openApp:
            switch language {
            case .korean: return "알람 열기"
            case .english: return "Open Matuta"
            }

        case .openAlarmsWindow:
            switch language {
            case .korean: return "알람 창 열기"
            case .english: return "Open Alarms Window"
            }

        case .nightstand:
            switch language {
            case .korean: return "나이트스탠드"
            case .english: return "Nightstand"
            }

        case .quit:
            switch language {
            case .korean: return "종료"
            case .english: return "Quit"
            }

        case .esc:
            return "ESC"

        case .noActiveAlarmsShort:
            switch language {
            case .korean: return "켜진 알람 없음"
            case .english: return "No Alarms On"
            }

        case .quickNap20:
            switch language {
            case .korean: return "20분 낮잠"
            case .english: return "20m Nap"
            }

        case .quickNap45:
            switch language {
            case .korean: return "45분 집중"
            case .english: return "45m Focus"
            }

        case .quickNap60:
            switch language {
            case .korean: return "1시간 숙면"
            case .english: return "1h Sleep"
            }

        case .wakeSoundPrompt:
            switch language {
            case .korean: return "무엇으로 깨울까요"
            case .english: return "Wake up sound"
            }

        case .collapse:
            switch language {
            case .korean: return "접기"
            case .english: return "Collapse"
            }

        case .browseTonesAndFiles:
            switch language {
            case .korean: return "벨소리 / 파일 찾아보기"
            case .english: return "Browse tones & files"
            }

        case .omniboxPlaceholder:
            switch language {
            case .korean: return "사운드 검색 또는 URL/경로 붙여넣기"
            case .english: return "Search tones, paste URL or file path..."
            }

        case .paste:
            switch language {
            case .korean: return "붙여넣기"
            case .english: return "Paste"
            }

        case .builtInTones:
            switch language {
            case .korean: return "내장 사운드"
            case .english: return "Built-in Tones"
            }

        case .builtInToneColon:
            switch language {
            case .korean: return "내장 벨소리:"
            case .english: return "Built-in Tone:"
            }

        case .localFile:
            switch language {
            case .korean: return "로컬 파일"
            case .english: return "Local File"
            }

        case .localAudio:
            switch language {
            case .korean: return "로컬 오디오"
            case .english: return "Local Audio"
            }

        case .localAudioFile:
            switch language {
            case .korean: return "음악 파일"
            case .english: return "Audio File"
            }

        case .chooseLocalFile:
            switch language {
            case .korean: return "로컬 파일 선택..."
            case .english: return "Choose Local File..."
            }

        case .streamRadio:
            switch language {
            case .korean: return "스트림 라디오"
            case .english: return "Stream Radio"
            }

        case .spotify:
            return "Spotify"

        case .spotifyWithBackup:
            switch language {
            case .korean: return "Spotify (백업음 보호)"
            case .english: return "Spotify (Backup tone)"
            }

        case .appleMusic:
            return "Apple Music"

        case .webAudio:
            switch language {
            case .korean: return "웹"
            case .english: return "Web"
            }

        case .webWithBackup:
            switch language {
            case .korean: return "웹 스트림 (백업음 보호)"
            case .english: return "Web Stream (Backup tone)"
            }

        case .chooseFile:
            switch language {
            case .korean: return "파일 선택..."
            case .english: return "Choose File..."
            }

        case .preview:
            switch language {
            case .korean: return "미리듣기"
            case .english: return "Preview"
            }

        case .stop:
            switch language {
            case .korean: return "중지"
            case .english: return "Stop"
            }

        case .themeMidnight:
            switch language {
            case .korean: return "아늑한 밤 (모닥불)"
            case .english: return "Cozy Midnight (Campfire)"
            }

        case .themeOat:
            switch language {
            case .korean: return "오트밀 (따뜻한 우유)"
            case .english: return "Oatmeal (Warm Milk)"
            }

        case .themeMatcha:
            switch language {
            case .korean: return "말차 (아침 숲)"
            case .english: return "Matcha (Morning Forest)"
            }

        case .themeSunset:
            switch language {
            case .korean: return "선셋 (노을빛 복숭아)"
            case .english: return "Sunset (Golden Peach)"
            }

        case .themeLavender:
            switch language {
            case .korean: return "라벤더 (새벽 구름)"
            case .english: return "Lavender (Dawn Clouds)"
            }

        case .themeCedar:
            switch language {
            case .korean: return "원목 (드립 커피)"
            case .english: return "Cedar (Drip Coffee)"
            }

        case .settingsTitle:
            switch language {
            case .korean: return "설정"
            case .english: return "Settings"
            }

        case .language:
            switch language {
            case .korean: return "언어"
            case .english: return "Language"
            }

        case .languageSystem:
            switch language {
            case .korean: return "시스템"
            case .english: return "System"
            }

        case .languageKorean:
            return "한국어"

        case .languageEnglish:
            return "English"

        default:
            return ""
        }
    }
}
