import Testing
import Foundation
@testable import MatutaCore

private func makeTempStore() -> (AlarmStore, URL) {
    let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("matuta-test-\(UUID().uuidString)")
    let file = dir.appendingPathComponent("alarms.json")
    return (AlarmStore(fileURL: file), dir)
}

@Test("저장한 알람을 다시 읽으면 그대로다")
func saveThenLoadRoundTrip() throws {
    let (store, dir) = makeTempStore()
    defer { try? FileManager.default.removeItem(at: dir) }

    let alarms = [
        Alarm(hour: 7, minute: 0, weekdays: [.monday, .friday]),
        Alarm(hour: 9, minute: 30, label: "주말"),
    ]

    try store.save(alarms)

    #expect(store.load() == alarms)
}

@Test("파일이 없으면 빈 배열을 준다")
func loadMissingFileGivesEmpty() {
    let (store, dir) = makeTempStore()
    defer { try? FileManager.default.removeItem(at: dir) }

    #expect(store.load().isEmpty)
}

@Test("JSON이 깨졌으면 빈 배열을 주고 원본을 옆에 남긴다")
func loadCorruptFileGivesEmptyAndKeepsBackup() throws {
    let (store, dir) = makeTempStore()
    defer { try? FileManager.default.removeItem(at: dir) }

    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let file = dir.appendingPathComponent("alarms.json")
    try Data("{ 이건 JSON이 아니다".utf8).write(to: file)

    #expect(store.load().isEmpty)

    // 사용자 데이터를 조용히 버리지 않는다.
    let leftovers = try FileManager.default.contentsOfDirectory(atPath: dir.path)
    #expect(leftovers.contains { $0.hasPrefix("alarms-corrupt-") })
}

@Test("저장은 기존 내용을 완전히 대체한다")
func saveReplacesPreviousContents() throws {
    let (store, dir) = makeTempStore()
    defer { try? FileManager.default.removeItem(at: dir) }

    try store.save([Alarm(hour: 7, minute: 0), Alarm(hour: 8, minute: 0)])
    try store.save([Alarm(hour: 9, minute: 0)])

    let loaded = store.load()
    #expect(loaded.count == 1)
    #expect(loaded.first?.hour == 9)
}

@Test("첫 실행용 알람은 꺼진 채로 하나 들어 있다")
func seedAlarmIsSingleAndDisabled() {
    // 설계 원칙: 첫 실행 시 빈 화면을 보여주지 않는다.
    #expect(AlarmStore.seedAlarms.count == 1)
    #expect(AlarmStore.seedAlarms[0].hour == 7)
    #expect(AlarmStore.seedAlarms[0].minute == 0)
    #expect(AlarmStore.seedAlarms[0].isEnabled == false)
}
