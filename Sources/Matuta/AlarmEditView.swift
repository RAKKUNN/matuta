import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MatutaCore

struct AlarmEditView: View {
    @State private var alarm: Alarm
    @State private var omniboxText: String = ""
    @State private var isDropTargeted: Bool = false
    private let onSave: (Alarm) -> Void
    private let onCancel: () -> Void

    init(
        alarm: Alarm,
        onSave: @escaping (Alarm) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _alarm = State(initialValue: alarm)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 16) {
            timeField
            weekdayPicker
            soundSection
            volumeSection

            HStack {
                Button("취소", role: .cancel) { onCancel() }
                Spacer()
                Button("저장") { onSave(alarm) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            initializeOmniboxText()
        }
    }

    // 드럼 휠 대신 키보드로 친다. Mac에는 키보드가 있다.
    private var timeField: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                TextField("", value: $alarm.hour, format: .number)
                    .frame(width: 62)
                Text(":")
                TextField("", value: $alarm.minute, format: .number)
                    .frame(width: 62)
            }
            .textFieldStyle(.plain)
            .font(.system(size: 42, weight: .thin))
            .monospacedDigit()
            .multilineTextAlignment(.center)

            Text("숫자를 입력하세요")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .onChange(of: alarm.hour) { _, new in
            alarm.hour = min(23, max(0, new))
        }
        .onChange(of: alarm.minute) { _, new in
            alarm.minute = min(59, max(0, new))
        }
    }

    private var weekdayPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("반복").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                ForEach(Weekday.displayOrder, id: \.self) { day in
                    Button(day.shortName) {
                        if alarm.weekdays.contains(day) {
                            alarm.weekdays.remove(day)
                        } else {
                            alarm.weekdays.insert(day)
                        }
                    }
                    .buttonStyle(.borderless)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(alarm.weekdays.contains(day) ? Color.accentColor : Color.secondary.opacity(0.15))
                    .foregroundStyle(alarm.weekdays.contains(day) ? Color.white : Color.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    // 통합 옴니박스 (파일 드롭, 링크 붙여넣기, 텍스트 검색, 파일 탐색기)
    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("무엇으로 깨울까요").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("찾아보기") {
                    selectLocalFile()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }

            // 옴니박스 단일 입력창
            HStack {
                sourceIcon
                TextField("링크 붙여넣기, 파일 드롭, 벨소리 입력...", text: $omniboxText)
                    .textFieldStyle(.plain)
                    .onChange(of: omniboxText) { _, new in
                        handleOmniboxInput(new)
                    }
            }
            .padding(8)
            .background(isDropTargeted ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isDropTargeted ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleFileDrop(providers)
            }

            // 자동 판별 결과 뱃지
            sourceBadge

            // 인터넷 필요 시 안내 문구
            if isNetworkRequired {
                Text("인터넷이 필요한 소스입니다 — 실패하면 Radar가 대신 울립니다")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            // 빠른 프리셋 칩
            presetChips
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("볼륨").font(.caption).foregroundStyle(.secondary)
            Slider(value: $alarm.volume, in: 0...1)
            Toggle("서서히 커지기", isOn: $alarm.fadeIn)
            Toggle("스누즈 9분", isOn: Binding(
                get: { alarm.snoozeMinutes != nil },
                set: { alarm.snoozeMinutes = $0 ? 9 : nil }
            ))
        }
    }

    // MARK: - Helpers & Presets

    private var sourceIcon: some View {
        Group {
            switch alarm.source {
            case .builtIn:
                Image(systemName: "bell.fill").foregroundStyle(.yellow)
            case .localFile:
                Image(systemName: "music.note").foregroundStyle(.blue)
            case .streamURL:
                Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(.orange)
            case .appleMusic:
                Image(systemName: "applelogo").foregroundStyle(.red)
            case .spotify:
                Image(systemName: "waveform.circle.fill").foregroundStyle(.green)
            case .web:
                Image(systemName: "globe").foregroundStyle(.cyan)
            }
        }
    }

    private var sourceBadge: some View {
        HStack(spacing: 4) {
            Text("인식된 소스:")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(sourceDescription)
                .font(.caption2.bold())
                .foregroundStyle(.primary)
        }
    }

    private var isNetworkRequired: Bool {
        switch alarm.source {
        case .builtIn, .localFile:
            return false
        case .streamURL, .appleMusic, .spotify, .web:
            return true
        }
    }

    private var sourceDescription: String {
        switch alarm.source {
        case .builtIn(let name):
            return "내장 사운드 (\(name))"
        case .localFile(let bookmark):
            if let url = LocalFileSource.resolve(bookmark: bookmark) {
                return "로컬 파일 (\(url.lastPathComponent))"
            }
            return "로컬 오디오 파일"
        case .streamURL(let url):
            return "라디오 스트림 (\(url.host ?? "URL"))"
        case .appleMusic:
            return "Apple Music"
        case .spotify:
            return "Spotify (백업음 동시 재생)"
        case .web(let url):
            return "웹 URL (\(url.host ?? "웹"))"
        }
    }

    private var presetChips: some View {
        HStack(spacing: 6) {
            presetChip(title: "🔔 Radar", source: .builtIn(name: "Radar"))
            presetChip(title: "🟢 Spotify", source: .spotify(uri: "spotify:user:spotify:playlist:37i9dQZF1DXcBWIGoYBM5M"))
            presetChip(title: "📻 스트림", source: .streamURL(URL(string: "https://stream.radioparadise.com/aac-320")!))
            Spacer()
        }
        .padding(.top, 2)
    }

    private func presetChip(title: String, source: SoundSourceRef) -> some View {
        Button(title) {
            alarm.source = source
            initializeOmniboxText()
        }
        .buttonStyle(.borderless)
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.12))
        .clipShape(Capsule())
    }

    private func initializeOmniboxText() {
        switch alarm.source {
        case .builtIn(let name):
            omniboxText = name
        case .localFile(let bookmark):
            if let url = LocalFileSource.resolve(bookmark: bookmark) {
                omniboxText = url.lastPathComponent
            } else {
                omniboxText = "로컬 파일"
            }
        case .streamURL(let url):
            omniboxText = url.absoluteString
        case .appleMusic(let id):
            omniboxText = id
        case .spotify(let uri):
            omniboxText = uri
        case .web(let url):
            omniboxText = url.absoluteString
        }
    }

    private func handleOmniboxInput(_ text: String) {
        let parsed = OmniboxParser.parse(text: text)
        alarm.source = parsed
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            DispatchQueue.main.async {
                alarm.source = OmniboxParser.makeLocalFileRef(for: url)
                omniboxText = url.lastPathComponent
            }
        }
        return true
    }

    private func selectLocalFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.audio]
        if panel.runModal() == .OK, let url = panel.url {
            alarm.source = OmniboxParser.makeLocalFileRef(for: url)
            omniboxText = url.lastPathComponent
        }
    }
}
