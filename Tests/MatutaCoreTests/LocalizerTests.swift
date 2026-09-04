import Testing
import Foundation
@testable import MatutaCore

@Test("Localizer: 모든 LocalizedText 키가 한국어와 영어에서 비어있지 않은 문자열을 반환한다")
func testAllLocalizedKeysNonEmpty() {
    let allKeys: [LocalizedText] = [
        // Preflight
        .headphonesConnected,
        .switchToSpeaker,
        .builtInSpeakerReady,
        .systemMuted,
        .unmuteToSafeVolume,
        .lowVolume(percent: 25),
        .adjustToSafeVolume,
        .wakeNotScheduled,
        .automationDenied(target: .spotify),
        .automationDenied(target: .appleMusic),
        .openSettings,
        .automationNotDetermined(target: .spotify),
        .automationNotDetermined(target: .appleMusic),
        .requestPermission,
        .automationNotInstalled(target: .spotify),
        .automationNotInstalled(target: .appleMusic),
        .speakerProtectionReady,
        .sleepPreventionActive,
        .allReady,
        .builtInSpeakerProtected,
        .wakeScheduled,

        // Alarm List
        .alarmListTitle,
        .addAlarm,
        .editAlarm,
        .newAlarm,
        .cancel,
        .save,
        .delete,
        .duplicate,
        .edit,
        .noAlarms,
        .noActiveAlarms,
        .alarmCount(3),
        .speakerStatus(volume: 80),
        .everyday,
        .weekdays,
        .weekends,
        .once,
        .snoozing,
        .nextAlarm,
        .nextAlarmAt("07:00"),

        // Alarm Edit & Options
        .repeatLabel,
        .soundLabel,
        .optionsLabel,
        .alarmName,
        .alarmNamePlaceholder,
        .snooze,
        .minutes(9),
        .gradualVolume,
        .gradualVolumeDescription,

        // Weekdays & Time
        .am,
        .pm,
        .sundayShort,
        .mondayShort,
        .tuesdayShort,
        .wednesdayShort,
        .thursdayShort,
        .fridayShort,
        .saturdayShort,

        // Countdowns & Firing
        .alarmCountdownHoursMinutes(hours: 2, minutes: 15),
        .alarmCountdownMinutes(minutes: 40),
        .alarmCountdownSoon,
        .dismissAlarm,
        .dismissAlarmSpace,
        .snoozeWithMinutes(9),
        .pressSpaceToDismiss,
        .alarmFiring,
        .openApp,
        .nightstand,
        .quit,
        .esc,

        // Omnibox & Sources
        .omniboxPlaceholder,
        .builtInTones,
        .localFile,
        .localAudioFile,
        .streamRadio,
        .spotify,
        .appleMusic,
        .webAudio,
        .chooseFile,
        .preview,
        .stop,

        // Themes
        .themeMidnight,
        .themeOat,
        .themeMatcha,
        .themeSunset,
        .themeLavender,
        .themeCedar,

        // Settings
        .settingsTitle,
        .language,
        .languageSystem,
        .languageKorean,
        .languageEnglish,

        // Apps
        .appName(.spotify),
        .appName(.appleMusic)
    ]

    for key in allKeys {
        let ko = Localizer.string(key, .korean)
        let en = Localizer.string(key, .english)

        #expect(!ko.isEmpty, "Korean translation missing for \(key)")
        #expect(!en.isEmpty, "English translation missing for \(key)")
    }
}

@Test("Localizer: 매개변수가 포함된 키는 양쪽 언어 모두에서 해당 인자 값을 포함한다")
func testParameterizedKeysContainValues() {
    let lowVol = LocalizedText.lowVolume(percent: 18)
    #expect(Localizer.string(lowVol, .korean).contains("18"))
    #expect(Localizer.string(lowVol, .english).contains("18"))

    let countdownHM = LocalizedText.alarmCountdownHoursMinutes(hours: 3, minutes: 45)
    #expect(Localizer.string(countdownHM, .korean).contains("3"))
    #expect(Localizer.string(countdownHM, .korean).contains("45"))
    #expect(Localizer.string(countdownHM, .english).contains("3"))
    #expect(Localizer.string(countdownHM, .english).contains("45"))

    let snooze = LocalizedText.snoozeWithMinutes(7)
    #expect(Localizer.string(snooze, .korean).contains("7"))
    #expect(Localizer.string(snooze, .english).contains("7"))

    let appSpotify = LocalizedText.automationDenied(target: .spotify)
    #expect(Localizer.string(appSpotify, .korean).contains("Spotify"))
    #expect(Localizer.string(appSpotify, .english).contains("Spotify"))

    let appMusic = LocalizedText.automationDenied(target: .appleMusic)
    #expect(Localizer.string(appMusic, .korean).contains("음악"))
    #expect(Localizer.string(appMusic, .english).contains("Music"))
}
