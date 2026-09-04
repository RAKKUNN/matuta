import Foundation

/// 알람 및 스누즈 영속 페이로드
public struct AlarmStorePayload: Codable, Sendable, Equatable {
    public var alarms: [Alarm]
    public var snooze: SnoozeState?

    public init(alarms: [Alarm], snooze: SnoozeState? = nil) {
        self.alarms = alarms
        self.snooze = snooze
    }
}

/// 알람 목록 및 활성 스누즈를 JSON 파일 하나에 안전하게 저장한다.
/// - `~/Library/Application Support/Matuta/alarms.json` 표준 샌드박스 경로 사용
/// - 저장 시 원자적 쓰기(`options: .atomic`) 및 자동 백업(`.bak`) 생성
/// - 레거시 파일 마이그레이션 및 단일 배열 JSON 하위 호환 지원
public struct AlarmStore: Sendable {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static var defaultFileURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Matuta", isDirectory: true)
            .appendingPathComponent("alarms.json")
    }

    public static func seedAlarms(for language: ResolvedLanguage) -> [Alarm] {
        [
            Alarm(
                hour: 7,
                minute: 0,
                weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                label: Localizer.string(.seedAlarmLabel, language),
                source: .builtIn(.default),
                volume: 0.8,
                fadeIn: true,
                isEnabled: false
            )
        ]
    }

    public static var seedAlarms: [Alarm] {
        let resolved = LanguageResolver.resolve(.system, preferredLanguages: Locale.preferredLanguages)
        return seedAlarms(for: resolved)
    }

    /// 알람 목록과 스누즈 상태를 함께 로드한다.
    public func loadPayload() -> AlarmStorePayload {
        migrateLegacyFileIfNeeded()

        guard let data = try? Data(contentsOf: fileURL) else {
            return AlarmStorePayload(alarms: [])
        }

        // 1. 신규 구조체(AlarmStorePayload)로 디코딩 시도
        if let payload = try? JSONDecoder().decode(AlarmStorePayload.self, from: data) {
            return payload
        }

        // 2. 레거시 [Alarm] 배열 포맷 하위 호환 디코딩
        if let alarms = try? JSONDecoder().decode([Alarm].self, from: data) {
            return AlarmStorePayload(alarms: alarms)
        }

        quarantineCorruptFile()
        return loadPayloadFromBackup()
    }

    /// 읽기는 절대 실패하지 않는다. 알람앱이 저장 파일 문제로 못 뜨면 안 된다.
    public func load() -> [Alarm] {
        loadPayload().alarms
    }

    /// 알람 목록 및 스누즈 상태를 원자적으로 저장한다.
    public func savePayload(_ payload: AlarmStorePayload) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )

        // 기존 파일이 있다면 백업 생성
        let backupURL = fileURL.appendingPathExtension("bak")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: fileURL, to: backupURL)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(payload).write(to: fileURL, options: .atomic)
    }

    public func save(_ alarms: [Alarm]) throws {
        let existingSnooze = loadPayload().snooze
        try savePayload(AlarmStorePayload(alarms: alarms, snooze: existingSnooze))
    }

    /// 백업 파일로부터 복원 시도
    private func loadPayloadFromBackup() -> AlarmStorePayload {
        let backupURL = fileURL.appendingPathExtension("bak")
        guard let data = try? Data(contentsOf: backupURL) else {
            return AlarmStorePayload(alarms: [])
        }
        if let payload = try? JSONDecoder().decode(AlarmStorePayload.self, from: data) {
            return payload
        }
        if let alarms = try? JSONDecoder().decode([Alarm].self, from: data) {
            return AlarmStorePayload(alarms: alarms)
        }
        return AlarmStorePayload(alarms: [])
    }

    /// 깨진 파일을 조용히 덮어쓰지 않고 옆에 보존
    private func quarantineCorruptFile() {
        let stamp = Int(Date().timeIntervalSince1970)
        let corruptBackup = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("alarms-corrupt-\(stamp).json")
        try? FileManager.default.moveItem(at: fileURL, to: corruptBackup)
    }

    /// 홈 디렉토리의 레거시 파일 `~/.matuta_alarms.json`이 존재할 경우 표준 위치로 이전
    private func migrateLegacyFileIfNeeded() {
        let legacyURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".matuta_alarms.json")
        guard FileManager.default.fileExists(atPath: legacyURL.path) && !FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.moveItem(at: legacyURL, to: fileURL)
    }
}
