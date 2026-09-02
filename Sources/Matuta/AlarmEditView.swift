import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MatutaCore

enum SourceTab: String, CaseIterable, Identifiable {
    case builtIn = "벨소리"
    case file = "파일"
    case spotify = "Spotify"
    case web = "유튜브/웹"
    case radio = "라디오"
    case appleMusic = "Music"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .builtIn: return "bell.fill"
        case .file: return "music.note"
        case .spotify: return "waveform.circle.fill"
        case .web: return "play.rectangle.fill"
        case .radio: return "antenna.radiowaves.left.and.right"
        case .appleMusic: return "applelogo"
        }
    }
}

struct AlarmEditView: View {
    @State private var alarm: Alarm
    @State private var selectedTab: SourceTab = .builtIn
    @State private var builtInName: String = "Radar"
    @State private var localFileName: String = ""
    @State private var spotifyInput: String = ""
    @State private var webInput: String = "https://www.youtube.com/watch?v=jfKfPfyJRdk" // Lofi Girl
    @State private var radioInput: String = "https://stream.radioparadise.com/aac-320"
    @State private var appleMusicInput: String = ""
    @State private var isDropTargeted: Bool = false
    @State private var isPreviewing: Bool = false
    @State private var previewPlayer = TonePlayer()

    @State private var isPM: Bool = false
    @State private var hour12: Int = 7

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
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button("취소") {
                    stopPreview()
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text("알람 설정")
                    .font(.system(size: 15, weight: .bold))

                Spacer()

                Button("저장") {
                    stopPreview()
                    syncAlarmSource()
                    syncTime24()
                    onSave(alarm)
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Color.accentColor)
                .clipShape(Capsule())
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 20) {
                    // 1. 대형 시계 타임 피커
                    timePickerSection

                    // 2. 반복 요일 설정
                    weekdaySection

                    // 3. 라벨 입력
                    labelSection

                    // 4. 사운드 소스 선택
                    soundSourceSection

                    // 5. 볼륨 및 옵션
                    optionsSection
                }
                .padding(20)
            }
        }
        .frame(width: 440, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            initializeState()
        }
        .onDisappear {
            stopPreview()
        }
    }

    // MARK: - 1. 대형 시계 타임 피커

    private var timePickerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // 시간 입력 박스
                HStack(spacing: 2) {
                    TextField("", value: $hour12, format: .number)
                        .frame(width: 60)
                    Text(":")
                        .font(.system(size: 44, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(.secondary)
                    TextField("", value: $alarm.minute, format: .number)
                        .frame(width: 60)
                }
                .textFieldStyle(.plain)
                .font(.system(size: 46, weight: .light, design: .rounded))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)))
                )

                // AM / PM 세그먼트 스위치
                VStack(spacing: 4) {
                    Button("AM") { isPM = false; syncTime24() }
                        .font(.system(size: 12, weight: !isPM ? .bold : .medium))
                        .frame(width: 44, height: 26)
                        .background(!isPM ? Color.accentColor : Color.primary.opacity(0.06))
                        .foregroundStyle(!isPM ? Color.white : Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .buttonStyle(.plain)

                    Button("PM") { isPM = true; syncTime24() }
                        .font(.system(size: 12, weight: isPM ? .bold : .medium))
                        .frame(width: 44, height: 26)
                        .background(isPM ? Color.accentColor : Color.primary.opacity(0.06))
                        .foregroundStyle(isPM ? Color.white : Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .buttonStyle(.plain)
                }
            }

            Text("시간을 클릭하여 키보드로 직접 입력할 수 있습니다")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .onChange(of: hour12) { _, new in
            hour12 = min(12, max(1, new))
            syncTime24()
        }
        .onChange(of: alarm.minute) { _, new in
            alarm.minute = min(59, max(0, new))
        }
    }

    // MARK: - 2. 반복 요일 설정

    private var weekdaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("반복")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()

                // 퀵 프리셋
                HStack(spacing: 4) {
                    quickDayPreset("주중", days: [.monday, .tuesday, .wednesday, .thursday, .friday])
                    quickDayPreset("주말", days: [.saturday, .sunday])
                    quickDayPreset("매일", days: Set(Weekday.allCases))
                    quickDayPreset("안 함", days: [])
                }
            }

            HStack(spacing: 6) {
                ForEach(Weekday.displayOrder, id: \.self) { day in
                    let isSelected = alarm.weekdays.contains(day)
                    Button(action: {
                        if isSelected {
                            alarm.weekdays.remove(day)
                        } else {
                            alarm.weekdays.insert(day)
                        }
                    }) {
                        Text(day.shortName)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                            .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickDayPreset(_ title: String, days: Set<Weekday>) -> some View {
        Button(title) {
            alarm.weekdays = days
        }
        .buttonStyle(.plain)
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.primary.opacity(0.06))
        .clipShape(Capsule())
        .foregroundStyle(.secondary)
    }

    // MARK: - 3. 알람 라벨

    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("라벨")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("알람 이름 (예: 기상, 출근, 회의)", text: Binding(
                get: { alarm.label ?? "" },
                set: { alarm.label = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.primary.opacity(0.08)))
            )
        }
    }

    // MARK: - 4. 사운드 소스 선택

    private var soundSourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("사운드")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            // 세그먼트 탭
            HStack(spacing: 2) {
                ForEach(SourceTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button(action: {
                        selectedTab = tab
                        stopPreview()
                        syncAlarmSource()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 10))
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color.accentColor : Color.clear)
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // 탭별 콘텐츠
            tabContentCard
        }
    }

    private var tabContentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch selectedTab {
            case .builtIn:
                HStack {
                    Picker("벨소리", selection: $builtInName) {
                        ForEach(TonePattern.allBuiltInNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .onChange(of: builtInName) { _, _ in
                        stopPreview()
                        syncAlarmSource()
                    }

                    Spacer()

                    Button(action: toggleBuiltInPreview) {
                        HStack(spacing: 4) {
                            Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                                .font(.system(size: 10))
                            Text(isPreviewing ? "정지" : "미리듣기")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Text("✨ 100% 합성 파형으로 파일 손상이나 인터넷 끊김 없이 항상 울립니다.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

            case .file:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundStyle(.cyan)
                        Text(localFileName.isEmpty ? "선택된 파일 없음" : localFileName)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("파일 찾기...") {
                            selectLocalFile()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    Text("💡 MP3, M4A, WAV 등 원하는 음악 파일을 창으로 직접 드래그 앤 드롭해도 됩니다.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                    handleFileDrop(providers)
                }

            case .spotify:
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Spotify 링크 또는 URI", text: $spotifyInput)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.08)))
                        .onChange(of: spotifyInput) { _, _ in syncAlarmSource() }

                    HStack(spacing: 4) {
                        Text("추천:").font(.system(size: 10)).foregroundStyle(.tertiary)
                        presetChip("Top 50", text: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M")
                        presetChip("어쿠스틱", text: "spotify:playlist:37i9dQZF1DX2MyUCdfq5Dg")
                        presetChip("Lofi", text: "spotify:playlist:37i9dQZF1DXdLEN7aqioXM")
                    }

                    Text("🛡️ Spotify 실행과 동시에 Radar 백업음이 함께 재생되어 기상을 보장합니다.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

            case .web:
                VStack(alignment: .leading, spacing: 8) {
                    TextField("유튜브 영상 / 라이브 링크 또는 웹 URL", text: $webInput)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.08)))
                        .onChange(of: webInput) { _, _ in syncAlarmSource() }

                    HStack(spacing: 4) {
                        Text("추천:").font(.system(size: 10)).foregroundStyle(.tertiary)
                        webPresetChip("Lofi Girl", url: "https://www.youtube.com/watch?v=jfKfPfyJRdk")
                        webPresetChip("카페 재즈", url: "https://www.youtube.com/watch?v=DXUAyRRkI6k")
                        webPresetChip("빗소리", url: "https://www.youtube.com/watch?v=mPZkdNFkNps")
                    }

                    Text("🌐 알람 시각에 브라우저가 열리며 화면의 [알람 끄기] 버튼으로 즉시 해제할 수 있습니다.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

            case .radio:
                VStack(alignment: .leading, spacing: 8) {
                    TextField("라디오 스트림 URL", text: $radioInput)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.08)))
                        .onChange(of: radioInput) { _, _ in syncAlarmSource() }

                    HStack(spacing: 4) {
                        Text("추천:").font(.system(size: 10)).foregroundStyle(.tertiary)
                        radioPresetChip("Paradise", url: "https://stream.radioparadise.com/aac-320")
                        radioPresetChip("Mellow", url: "https://stream.radioparadise.com/mellow-aac-320")
                        radioPresetChip("Classic", url: "https://icecast.vrt.be/klara-high.mp3")
                    }

                    Text("📡 스트림 연결 실패 시 즉시 Radar 백업음으로 자동 대체됩니다.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

            case .appleMusic:
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Apple Music 앨범/트랙 URL", text: $appleMusicInput)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.08)))
                        .onChange(of: appleMusicInput) { _, _ in syncAlarmSource() }

                    Text("🍎 Music 앱과 연동되어 정해진 시간에 재생을 시작합니다.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isDropTargeted ? Color.accentColor : Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - 5. 볼륨 및 옵션

    private var optionsSection: some View {
        VStack(spacing: 12) {
            // 볼륨 슬라이더
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("볼륨")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(alarm.volume * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $alarm.volume, in: 0...1)
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider().opacity(0.3)

            // 토글 옵션들
            Toggle("서서히 커지기 (점진적 볼륨 페이드인)", isOn: $alarm.fadeIn)
                .font(.system(size: 12, weight: .medium))

            Toggle("스누즈 9분 허용", isOn: Binding(
                get: { alarm.snoozeMinutes != nil },
                set: { alarm.snoozeMinutes = $0 ? 9 : nil }
            ))
            .font(.system(size: 12, weight: .medium))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.primary.opacity(0.05)))
        )
    }

    // MARK: - Helpers & Synchronization

    private func presetChip(_ title: String, text: String) -> some View {
        Button(title) {
            spotifyInput = text
            syncAlarmSource()
        }
        .buttonStyle(.plain)
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.primary.opacity(0.08))
        .clipShape(Capsule())
    }

    private func webPresetChip(_ title: String, url: String) -> some View {
        Button(title) {
            webInput = url
            syncAlarmSource()
        }
        .buttonStyle(.plain)
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.primary.opacity(0.08))
        .clipShape(Capsule())
    }

    private func radioPresetChip(_ title: String, url: String) -> some View {
        Button(title) {
            radioInput = url
            syncAlarmSource()
        }
        .buttonStyle(.plain)
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.primary.opacity(0.08))
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

    private func initializeState() {
        isPM = alarm.hour >= 12
        hour12 = alarm.hour == 0 ? 12 : (alarm.hour > 12 ? alarm.hour - 12 : alarm.hour)

        switch alarm.source {
        case .builtIn(let name):
            selectedTab = .builtIn
            builtInName = name
        case .localFile(let bookmark):
            selectedTab = .file
            if let url = LocalFileSource.resolve(bookmark: bookmark) {
                localFileName = url.lastPathComponent
            } else {
                localFileName = "로컬 음악 파일"
            }
        case .spotify(let uri):
            selectedTab = .spotify
            spotifyInput = uri
        case .web(let url):
            selectedTab = .web
            webInput = url.absoluteString
        case .streamURL(let url):
            selectedTab = .radio
            radioInput = url.absoluteString
        case .appleMusic(let id):
            selectedTab = .appleMusic
            appleMusicInput = id
        }
    }

    private func syncTime24() {
        if isPM {
            alarm.hour = hour12 == 12 ? 12 : hour12 + 12
        } else {
            alarm.hour = hour12 == 12 ? 0 : hour12
        }
    }

    private func syncAlarmSource() {
        switch selectedTab {
        case .builtIn:
            alarm.source = .builtIn(name: builtInName)
        case .file:
            break
        case .spotify:
            let parsed = OmniboxParser.parse(text: spotifyInput)
            if case .spotify = parsed {
                alarm.source = parsed
            } else if !spotifyInput.isEmpty {
                alarm.source = .spotify(uri: spotifyInput)
            }
        case .web:
            if let url = URL(string: webInput) {
                alarm.source = .web(url)
            }
        case .radio:
            if let url = URL(string: radioInput) {
                alarm.source = .streamURL(url)
            }
        case .appleMusic:
            alarm.source = .appleMusic(id: appleMusicInput.isEmpty ? "default" : appleMusicInput)
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
