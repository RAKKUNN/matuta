import Foundation

/// 알람 목록을 JSON 파일 하나에 저장한다. 데이터베이스는 쓰지 않는다.
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

    /// 첫 실행 때 넣을 알람. 빈 화면을 보여주지 않기 위한 것이므로 꺼둔다.
    public static var seedAlarms: [Alarm] {
        [Alarm(hour: 7, minute: 0, isEnabled: false)]
    }

    /// 읽기는 절대 실패하지 않는다. 알람앱이 저장 파일 문제로 못 뜨면 안 된다.
    public func load() -> [Alarm] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        do {
            return try JSONDecoder().decode([Alarm].self, from: data)
        } catch {
            quarantineCorruptFile()
            return []
        }
    }

    public func save(_ alarms: [Alarm]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        // 쓰다가 죽어도 반쪽짜리 파일이 남지 않게 한다.
        try encoder.encode(alarms).write(to: fileURL, options: .atomic)
    }

    /// 깨진 파일을 조용히 덮어쓰지 않고 옆에 치워둔다.
    private func quarantineCorruptFile() {
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("alarms-corrupt-\(stamp).json")
        try? FileManager.default.moveItem(at: fileURL, to: backup)
    }
}
