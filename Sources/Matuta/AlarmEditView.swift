import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MatutaCore

enum SourceTab: String, CaseIterable, Identifiable {
    case builtIn = "벨소리"
    case file = "파일"
    case spotify = "Spotify"
    case radio = "라디오"
    case appleMusic = "Music"
    case web = "웹"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .builtIn: return "bell.fill"
        case .file: return "music.note"
        case .spotify: return "waveform.circle.fill"
        case .radio: return "antenna.radiowaves.left.and.right"
        case .appleMusic: return "applelogo"
        case .web: return "globe"
        }
    }
}

struct AlarmEditView: View {
    @State private var alarm: Alarm
    @State private var selectedTab: SourceTab = .builtIn
    @State private var builtInName: String = "Radar"
    @State private var localFileName: String = ""
    @State private var spotifyInput: String = ""
    @State private var radioInput: String = "https://stream.radioparadise.com/aac-320"
    @State private var appleMusicInput: String = ""
    @State private var webInput: String = "https://www.youtube.com"
    @State private var isDropTargeted: Bool = false
    @State private var isPreviewing: Bool = false
    @State private var previewPlayer = TonePlayer()

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
                Button("취소", role: .cancel) {
                    stopPreview()
                    onCancel()
                }
                Spacer()
                Button("저장") {
                    stopPreview()
                    syncAlarmSource()
                    onSave(alarm)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            initializeFromAlarm()
        }
        .onDisappear {
            stopPreview()
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

            Text("시각을 입력하세요 (24시간 형식)")
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

    // 소스 선택 인터페이스
    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("무엇으로 깨울까요").font(.caption).foregroundStyle(.secondary)

            // 소스 탭 선택기
            Picker("", selection: $selectedTab) {
                ForEach(SourceTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTab) { _, _ in
                stopPreview()
                syncAlarmSource()
            }

            // 탭별 세부 설정 영역
            tabContent
                .padding(10)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.15), lineWidth: 1.5)
                )
                .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                    handleFileDrop(providers)
                }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .builtIn:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Picker("벨소리 선택", selection: $builtInName) {
                        ForEach(TonePattern.allBuiltInNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .onChange(of: builtInName) { _, _ in
                        stopPreview()
                        syncAlarmSource()
                    }

                    Button(isPreviewing ? "⏹️ 정지" : "▶️ 미리듣기") {
                        toggleBuiltInPreview()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                Text("순수 합성 비프음으로 파일 손상이나 네트워크 실패 없이 항상 울립니다.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        case .file:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(localFileName.isEmpty ? "선택된 파일 없음" : localFileName)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("파일 찾기...") {
                        selectLocalFile()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                Text("💡 MP3, M4A, WAV 등 원하는 음악 파일을 창으로 드래그 앤 드롭해도 됩니다.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        case .spotify:
            VStack(alignment: .leading, spacing: 6) {
                TextField("Spotify 트랙 또는 플레이리스트 URI / 링크", text: $spotifyInput)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: spotifyInput) { _, _ in syncAlarmSource() }

                HStack(spacing: 4) {
                    Text("프리셋:").font(.caption2).foregroundStyle(.tertiary)
                    presetChip(title: "Top Hits", text: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M")
                    presetChip(title: "모닝 어쿠스틱", text: "spotify:playlist:37i9dQZF1DX2MyUCdfq5Dg")
                    presetChip(title: "집중 피아노", text: "spotify:playlist:37i9dQZF1DX4sWSpwq3LiO")
                }

                Text("🛡️ Spotify 실행과 동시에 Radar 백업음이 함께 재생되어 무음 실패를 방지합니다.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        case .radio:
            VStack(alignment: .leading, spacing: 6) {
                TextField("라디오 스트림 URL", text: $radioInput)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: radioInput) { _, _ in syncAlarmSource() }

                HStack(spacing: 4) {
                    Text("추천:").font(.caption2).foregroundStyle(.tertiary)
                    radioPresetChip(title: "Paradise", url: "https://stream.radioparadise.com/aac-320")
                    radioPresetChip(title: "Mellow", url: "https://stream.radioparadise.com/mellow-aac-320")
                    radioPresetChip(title: "Classic", url: "https://icecast.vrt.be/klara-high.mp3")
                }

                Text("📡 스트림 연결 실패 시 즉시 Radar 백업음으로 자동 폴백됩니다.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        case .appleMusic:
            VStack(alignment: .leading, spacing: 6) {
                TextField("Apple Music 앨범/트랙 URL", text: $appleMusicInput)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: appleMusicInput) { _, _ in syncAlarmSource() }

                Text("🍎 Music 앱과 연동되어 정해진 시간에 재생을 시작합니다.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        case .web:
            VStack(alignment: .leading, spacing: 6) {
                TextField("웹사이트 또는 YouTube URL", text: $webInput)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: webInput) { _, _ in syncAlarmSource() }

                Text("🌐 기본 웹 브라우저로 열리며 Radar 백업음이 함께 울립니다.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("볼륨").font(.caption).foregroundStyle(.secondary)
            Slider(value: $alarm.volume, in: 0...1)
            Toggle("서서히 커지기 (페이드인)", isOn: $alarm.fadeIn)
            Toggle("스누즈 9분", isOn: Binding(
                get: { alarm.snoozeMinutes != nil },
                set: { alarm.snoozeMinutes = $0 ? 9 : nil }
            ))
        }
    }

    // MARK: - Helpers & Synchronization

    private func presetChip(title: String, text: String) -> some View {
        Button(title) {
            spotifyInput = text
            syncAlarmSource()
        }
        .buttonStyle(.borderless)
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.15))
        .clipShape(Capsule())
    }

    private func radioPresetChip(title: String, url: String) -> some View {
        Button(title) {
            radioInput = url
            syncAlarmSource()
        }
        .buttonStyle(.borderless)
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.15))
        .clipShape(Capsule())
    }

    private func toggleBuiltInPreview() {
        if isPreviewing {
            stopPreview()
        } else {
            isPreviewing = true
            let pattern = TonePattern.pattern(named: builtInName)
            previewPlayer.start(pattern: pattern, volume: alarm.volume, fadeIn: false)
        }
    }

    private func stopPreview() {
        if isPreviewing {
            previewPlayer.stop()
            isPreviewing = false
        }
    }

    private func initializeFromAlarm() {
        switch alarm.source {
        case .builtIn(let name):
            selectedTab = .builtIn
            builtInName = name
        case .localFile(let bookmark):
            selectedTab = .file
            if let url = LocalFileSource.resolve(bookmark: bookmark) {
                localFileName = url.lastPathComponent
            } else {
                localFileName = "로컬 파일"
            }
        case .streamURL(let url):
            selectedTab = .radio
            radioInput = url.absoluteString
        case .appleMusic(let id):
            selectedTab = .appleMusic
            appleMusicInput = id
        case .spotify(let uri):
            selectedTab = .spotify
            spotifyInput = uri
        case .web(let url):
            selectedTab = .web
            webInput = url.absoluteString
        }
    }

    private func syncAlarmSource() {
        switch selectedTab {
        case .builtIn:
            alarm.source = .builtIn(name: builtInName)
        case .file:
            // 로컬 파일 유지 (이미 설정된 bookmark 또는 기본값)
            break
        case .spotify:
            let parsed = OmniboxParser.parse(text: spotifyInput)
            if case .spotify = parsed {
                alarm.source = parsed
            } else if !spotifyInput.isEmpty {
                alarm.source = .spotify(uri: spotifyInput)
            }
        case .radio:
            if let url = URL(string: radioInput) {
                alarm.source = .streamURL(url)
            }
        case .appleMusic:
            alarm.source = .appleMusic(id: appleMusicInput.isEmpty ? "default" : appleMusicInput)
        case .web:
            if let url = URL(string: webInput) {
                alarm.source = .web(url)
            }
        }
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            DispatchQueue.main.async {
                selectedTab = .file
                localFileName = url.lastPathComponent
                alarm.source = OmniboxParser.makeLocalFileRef(for: url)
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
            selectedTab = .file
            localFileName = url.lastPathComponent
            alarm.source = OmniboxParser.makeLocalFileRef(for: url)
        }
    }
}
