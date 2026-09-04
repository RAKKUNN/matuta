import Foundation

/// 앱 전체에서 사용되는 현지화 가능한 텍스트 키 정의.
/// 연관값을 통해 언어별 문장 구조와 매개변수 삽입 위치를 타입 안전하게 수용한다.
public enum LocalizedText: Sendable, Equatable, Hashable {
    // MARK: - Preflight & System Audio / Defenses
    case headphonesConnected
    case switchToSpeaker
    case builtInSpeakerReady
    case systemMuted
    case unmuteToSafeVolume
    case lowVolume(percent: Int)
    case adjustToSafeVolume
    case wakeNotScheduled
    case automationDenied(target: AutomationTarget)
    case openSettings
    case automationNotDetermined(target: AutomationTarget)
    case requestPermission
    case automationNotInstalled(target: AutomationTarget)
    case speakerProtectionReady
    case sleepPreventionActive
    case allReady
    case builtInSpeakerProtected
    case wakeScheduled

    // MARK: - Alarm List & Main UI
    case alarmListTitle
    case addAlarm
    case editAlarm
    case newAlarm
    case cancel
    case save
    case delete
    case duplicate
    case edit
    case noAlarms
    case noActiveAlarms
    case alarmCount(Int)
    case speakerStatus(volume: Int)
    case everyday
    case weekdays
    case weekends
    case once
    case snoozing
    case nextAlarm
    case nextAlarmAt(String)

    // MARK: - Alarm Edit & Options
    case repeatLabel
    case soundLabel
    case optionsLabel
    case volumeLabel
    case alarmName
    case alarmNamePlaceholder
    case snooze
    case snoozeDescription
    case minutes(Int)
    case gradualVolume
    case gradualVolumeDescription

    // MARK: - Time & Weekdays
    case am
    case pm
    case sundayShort
    case mondayShort
    case tuesdayShort
    case wednesdayShort
    case thursdayShort
    case fridayShort
    case saturdayShort

    // MARK: - Countdowns & Firing
    case alarmCountdownHoursMinutes(hours: Int, minutes: Int)
    case alarmCountdownMinutes(minutes: Int)
    case alarmCountdownSoon
    case remaining(String)
    case dismissAlarm
    case dismissAlarmSpace
    case snoozeWithMinutes(Int)
    case pressSpaceToDismiss
    case alarmFiring
    case openApp
    case openAlarmsWindow
    case nightstand
    case quit
    case esc
    case noActiveAlarmsShort
    case quickNap20
    case quickNap45
    case quickNap60

    // MARK: - Omnibox & Audio Sources
    case wakeSoundPrompt
    case collapse
    case browseTonesAndFiles
    case omniboxPlaceholder
    case paste
    case builtInTones
    case builtInToneColon
    case localFile
    case localAudio
    case localAudioFile
    case chooseLocalFile
    case streamRadio
    case spotify
    case spotifyWithBackup
    case appleMusic
    case webAudio
    case webWithBackup
    case chooseFile
    case preview
    case stop

    // MARK: - Themes
    case themeMidnight
    case themeOat
    case themeMatcha
    case themeSunset
    case themeLavender
    case themeCedar

    // MARK: - Settings
    case settingsTitle
    case language
    case languageSystem
    case languageKorean
    case languageEnglish

    // MARK: - App Names
    case appName(AutomationTarget)
}
