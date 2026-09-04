import Foundation

/// 타입 안전한 LocalizedText를 ResolvedLanguage에 맞게 렌더링하는 순수 번역 엔진.
public enum Localizer {
    public static func string(_ text: LocalizedText, _ language: ResolvedLanguage) -> String {
        switch text {
        case .appName(let target):
            return stringForAppName(target, language)

        // Preflight & System Audio
        case .headphonesConnected, .switchToSpeaker, .builtInSpeakerReady,
             .systemMuted, .unmuteToSafeVolume, .lowVolume, .adjustToSafeVolume,
             .wakeNotScheduled, .automationDenied, .openSettings,
             .automationNotDetermined, .requestPermission, .automationNotInstalled,
             .speakerProtectionReady, .sleepPreventionActive, .allReady,
             .builtInSpeakerProtected, .wakeScheduled:
            return stringForPreflight(text, language)

        // Alarm List & Options
        case .alarmListTitle, .addAlarm, .editAlarm, .newAlarm, .cancel, .save,
             .delete, .duplicate, .edit, .noAlarms, .noActiveAlarms, .alarmCount,
             .speakerStatus, .everyday, .weekdays, .weekends, .once, .snoozing,
             .repeatLabel, .soundLabel, .optionsLabel, .alarmName, .alarmNamePlaceholder,
             .snooze, .minutes, .gradualVolume, .gradualVolumeDescription,
             .nextAlarm, .nextAlarmAt:
            return stringForAlarm(text, language)

        // Time, Weekday, Omnibox, Themes, Settings, Overlays
        case .am, .pm, .sundayShort, .mondayShort, .tuesdayShort, .wednesdayShort,
             .thursdayShort, .fridayShort, .saturdayShort,
             .alarmCountdownHoursMinutes, .alarmCountdownMinutes, .alarmCountdownSoon,
             .dismissAlarm, .dismissAlarmSpace, .snoozeWithMinutes, .pressSpaceToDismiss,
             .alarmFiring, .openApp, .nightstand, .quit, .esc,
             .omniboxPlaceholder, .builtInTones, .localFile, .localAudioFile,
             .streamRadio, .spotify, .appleMusic, .webAudio, .chooseFile, .preview, .stop,
             .themeMidnight, .themeOat, .themeMatcha, .themeSunset, .themeLavender, .themeCedar,
             .settingsTitle, .language, .languageSystem, .languageKorean, .languageEnglish:
            return stringForUI(text, language)
        }
    }

    static func stringForAppName(_ target: AutomationTarget, _ language: ResolvedLanguage) -> String {
        switch target {
        case .spotify:
            return "Spotify"
        case .appleMusic:
            switch language {
            case .korean: return "음악"
            case .english: return "Music"
            }
        }
    }
}
