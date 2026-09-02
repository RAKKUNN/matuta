import Foundation

/// 알람 목록을 JSON 파일 하나에 안전하게 저장한다.
/// - `~/Library/Application Support/Matuta/alarms.json` 표준 샌드박스 경로 사용
/// - 저장 시 원자적 쓰기(`options: .atomic`) 및 자동 백업(`.bak`) 생성
/// - 레거시 파일 마이그레이션 지원
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

    public static var seedAlarms: [Alarm] {
        [
            Alarm(
                hour: 7,
                minute: 0,
                weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                label: "상쾌한 아침",
                source: .builtIn(name: "Morning Harp"),
                volume: 0.8,
                fadeIn: true,
                isEnabled: false
            )
        ]
    }

    /// 읽기는 절대 실패하지 않는다. 알람앱이 저장 파일 문제로 못 뜨면 안 된다.
    public func load() -> [Alarm] {
        // 1. 레거시 파일 마이그레이션 검사
        migrateLegacyFileIfNeeded()

        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        do {
            return try JSONDecoder().decode([Alarm].self, from: data)
        } catch {
            quarantineCorruptFile()
            return loadFromBackup()
        }
    }

    public func save(_ alarms: [Alarm]) throws {
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
        try encoder.encode(alarms).write(to: fileURL, options: .atomic)
    }

    /// 백업 파일로부터 복원 시도
    private func loadFromBackup() -> [Alarm] {
        let backupURL = fileURL.appendingPathExtension("bak")
        guard let data = try? Data(contentsOf: backupURL),
              let alarms = try? JSONDecoder().decode([Alarm].self, from: data) else {
            return []
        }
        return alarms
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
