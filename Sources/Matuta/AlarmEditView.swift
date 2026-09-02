import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MatutaCore

enum SourceTab: String, CaseIterable, Identifiable {
    case builtIn = "벨소리"
    case file = "음악 파일"
    case spotify = "Spotify"
    case web = "YouTube/웹"
    case radio = "라디오"
    case appleMusic = "Music"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .builtIn: return "bell.fill"
        case .file: return "music.note"
        case .spotify: return "waveform"
        case .web: return "play.rectangle.fill"
        case .radio: return "antenna.radiowaves.left.and.right"
        case .appleMusic: return "apple.logo"
        }
    }
}

struct AlarmEditView: View {
    @State private var alarm: Alarm
    @State private var selectedTab: SourceTab = .builtIn
    @State private var builtInName: String = "Radar"
    @State private var localFileName: String = ""
    @State private var spotifyInput: String = ""
    @State private var webInput: String = "https://www.youtube.com/watch?v=jfKfPfyJRdk"
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
            // 상단 네비게이션 바
            headerBar

            Divider().opacity(0.15)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. 시계 타임 피커 & 퀵 타임 프리셋
                    timeSculptorSection

                    // 2. 반복 요일 설정
                    weekdaySection

                    // 3. 라벨 입력
                    labelSection

                    // 4. 사운드 스튜디오 데크
                    soundDeckSection

                    // 5. 볼륨 및 옵션
                    volumeOptionsSection
                }
                .padding(22)
            }
        }
        .frame(width: 440, height: 620)
        .background(MatutaTheme.baseBackground)
        .onAppear {
            initializeState()
        }
        .onDisappear {
            stopPreview()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button("취소") {
                stopPreview()
                onCancel()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(MatutaTheme.textSecondary)

            Spacer()

            Text("알람 설정")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(MatutaTheme.textPrimary)

            Spacer()

            Button("저장") {
                stopPreview()
                syncAlarmSource()
                syncTime24()
                onSave(alarm)
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.white.opacity(0.2), radius: 8, y: 2)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - 1. Time Sculptor

    private var timeSculptorSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // 디지털 시계 디스플레이
                HStack(spacing: 2) {
                    TextField("", value: $hour12, format: .number)
                        .frame(width: 64)
                    Text(":")
                        .font(.system(size: 46, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(MatutaTheme.textSecondary)
                        .offset(y: -2)
                    TextField("", value: $alarm.minute, format: .number)
                        .frame(width: 64)
                }
                .textFieldStyle(.plain)
                .font(.system(size: 48, weight: .light, design: .rounded))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .foregroundStyle(MatutaTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(MatutaTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(MatutaTheme.subtleStroke, lineWidth: 1)
                )

                // AM / PM 토글 바
                VStack(spacing: 4) {
                    Button(action: { isPM = false; syncTime24() }) {
                        Text("AM")
                            .font(.system(size: 12, weight: !isPM ? .bold : .medium))
                            .frame(width: 44, height: 28)
                            .background(!isPM ? MatutaTheme.primaryAccent : Color.white.opacity(0.06))
                            .foregroundStyle(!isPM ? Color.white : MatutaTheme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: { isPM = true; syncTime24() }) {
                        Text("PM")
                            .font(.system(size: 12, weight: isPM ? .bold : .medium))
                            .frame(width: 44, height: 28)
                            .background(isPM ? MatutaTheme.primaryAccent : Color.white.opacity(0.06))
                            .foregroundStyle(isPM ? Color.white : MatutaTheme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 퀵 타임 프리셋 칩
            HStack(spacing: 6) {
                quickTimeChip("06:30", h: 6, m: 30, pm: false)
                quickTimeChip("07:00", h: 7, m: 0, pm: false)
                quickTimeChip("07:30", h: 7, m: 30, pm: false)
                quickTimeChip("08:00", h: 8, m: 0, pm: false)
                quickTimeChip("08:30", h: 8, m: 30, pm: false)
            }
        }
        .onChange(of: hour12) { _, new in
            hour12 = min(12, max(1, new))
            syncTime24()
        }
        .onChange(of: alarm.minute) { _, new in
            alarm.minute = min(59, max(0, new))
        }
    }

    private func quickTimeChip(_ label: String, h: Int, m: Int, pm: Bool) -> some View {
        Button(action: {
            hour12 = h
            alarm.minute = m
            isPM = pm
            syncTime24()
        }) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(MatutaTheme.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(MatutaTheme.subtleStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 2. Weekday Scheduler

    private var weekdaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("반복")
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(1.0)
                    .foregroundStyle(MatutaTheme.textSecondary)

                Spacer()

                HStack(spacing: 4) {
                    quickDayPreset("주중", days: [.monday, .tuesday, .wednesday, .thursday, .friday])
                    quickDayPreset("주말", days: [.saturday, .sunday])
                    quickDayPreset("매일", days: Set(Weekday.allCases))
                    quickDayPreset("1회성", days: [])
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
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(isSelected ? MatutaTheme.primaryAccent : MatutaTheme.cardBackground)
                            .foregroundStyle(isSelected ? Color.white : MatutaTheme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .strokeBorder(isSelected ? Color.clear : MatutaTheme.subtleStroke, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickDayPreset(_ title: String, days: Set<Weekday>) -> some View {
        Button(action: { alarm.weekdays = days }) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MatutaTheme.textTertiary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. Label

    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("라벨")
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.0)
                .foregroundStyle(MatutaTheme.textSecondary)

            TextField("알람 이름 (예: 기상, 출근, 모닝 루틴)", text: Binding(
                get: { alarm.label ?? "" },
                set: { alarm.label = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundStyle(MatutaTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(MatutaTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(MatutaTheme.subtleStroke, lineWidth: 1)
            )
        }
    }

    // MARK: - 4. Sound Studio Deck

    private var soundDeckSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("사운드")
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.0)
                .foregroundStyle(MatutaTheme.textSecondary)

            // 세그먼트 탭
            HStack(spacing: 2) {
                ForEach(SourceTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button(action: {
                        selectedTab = tab
                        stopPreview()
                        syncAlarmSource()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 10))
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6.5)
                        .background(isSelected ? MatutaTheme.primaryAccent : Color.clear)
                        .foregroundStyle(isSelected ? Color.white : MatutaTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2.5)
            .background(MatutaTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(MatutaTheme.subtleStroke, lineWidth: 1)
            )

            // 탭별 인터랙티브 카드
            soundCardContent
                .padding(14)
                .background(MatutaTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isDropTargeted ? MatutaTheme.primaryAccent : MatutaTheme.subtleStroke, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var soundCardContent: some View {
        switch selectedTab {
        case .builtIn:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Picker("벨소리", selection: $builtInName) {
                        ForEach(TonePattern.allBuiltInNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: builtInName) { _, _ in
                        stopPreview()
                        syncAlarmSource()
                    }

                    Spacer()

                    Button(action: toggleBuiltInPreview) {
                        HStack(spacing: 5) {
                            Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                                .font(.system(size: 10))
                            Text(isPreviewing ? "정지" : "미리듣기")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(isPreviewing ? Color.black : Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5.5)
                        .background(isPreviewing ? MatutaTheme.sunriseAmber : Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Text("네트워크나 파일 손상 없이 언제든 100% 울리는 순수 합성 파형입니다.")
                    .font(.system(size: 11))
                    .foregroundStyle(MatutaTheme.textSecondary)
            }

        case .file:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 14))
                        .foregroundStyle(MatutaTheme.electricCyan)

                    Text(localFileName.isEmpty ? "선택된 음악 파일 없음" : localFileName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MatutaTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("파일 찾기...") {
                        selectLocalFile()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(MatutaTheme.primaryAccent)
                    .clipShape(Capsule())
                }

                Text("MP3, M4A, WAV 등 원하는 음악 파일을 이 창으로 직접 끌어다 놓아도 됩니다.")
                    .font(.system(size: 11))
                    .foregroundStyle(MatutaTheme.textSecondary)
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleFileDrop(providers)
            }

        case .spotify:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Spotify 링크 또는 URI", text: $spotifyInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(MatutaTheme.textPrimary)
                        .onChange(of: spotifyInput) { _, _ in syncAlarmSource() }

                    if let clip = NSPasteboard.general.string(forType: .string), clip.contains("spotify") {
                        Button("붙여넣기") {
                            spotifyInput = clip
                            syncAlarmSource()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(MatutaTheme.neonGreen)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 4) {
                    Text("추천:").font(.system(size: 10)).foregroundStyle(MatutaTheme.textTertiary)
                    presetChip("Top 50", text: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M")
                    presetChip("어쿠스틱", text: "spotify:playlist:37i9dQZF1DX2MyUCdfq5Dg")
                    presetChip("Lofi Beats", text: "spotify:playlist:37i9dQZF1DXdLEN7aqioXM")
                }

                Text("Spotify 실행과 동시에 Radar 백업음이 함께 재생되어 무음 실패를 방지합니다.")
                    .font(.system(size: 11))
                    .foregroundStyle(MatutaTheme.textSecondary)
            }

        case .web:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("YouTube 영상/라이브 링크 또는 웹 URL", text: $webInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(MatutaTheme.textPrimary)
                        .onChange(of: webInput) { _, _ in syncAlarmSource() }

                    if let clip = NSPasteboard.general.string(forType: .string), clip.contains("http") {
                        Button("붙여넣기") {
                            webInput = clip
                            syncAlarmSource()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(MatutaTheme.sunriseOrange)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 4) {
                    Text("추천:").font(.system(size: 10)).foregroundStyle(MatutaTheme.textTertiary)
                    webPresetChip("Lofi Girl", url: "https://www.youtube.com/watch?v=jfKfPfyJRdk")
                    webPresetChip("카페 재즈", url: "https://www.youtube.com/watch?v=DXUAyRRkI6k")
                    webPresetChip("빗소리", url: "https://www.youtube.com/watch?v=mPZkdNFkNps")
                }

                Text("알람 시각에 브라우저가 열리며 화면의 [알람 끄기] 버튼으로 즉시 해제할 수 있습니다.")
                    .font(.system(size: 11))
                    .foregroundStyle(MatutaTheme.textSecondary)
            }

        case .radio:
            VStack(alignment: .leading, spacing: 8) {
                TextField("라디오 스트림 URL", text: $radioInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(MatutaTheme.textPrimary)
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onChange(of: radioInput) { _, _ in syncAlarmSource() }

                HStack(spacing: 4) {
                    Text("추천:").font(.system(size: 10)).foregroundStyle(MatutaTheme.textTertiary)
                    radioPresetChip("Paradise", url: "https://stream.radioparadise.com/aac-320")
                    radioPresetChip("Mellow", url: "https://stream.radioparadise.com/mellow-aac-320")
                    radioPresetChip("Classic", url: "https://icecast.vrt.be/klara-high.mp3")
                }

                Text("스트림 연결 실패 시 즉시 Radar 백업음으로 자동 대체됩니다.")
                    .font(.system(size: 11))
                    .foregroundStyle(MatutaTheme.textSecondary)
            }

        case .appleMusic:
            VStack(alignment: .leading, spacing: 8) {
                TextField("Apple Music 앨범/트랙 URL", text: $appleMusicInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(MatutaTheme.textPrimary)
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onChange(of: appleMusicInput) { _, _ in syncAlarmSource() }

                Text("Music 앱과 연동되어 정해진 시간에 재생을 시작합니다.")
                    .font(.system(size: 11))
                    .foregroundStyle(MatutaTheme.textSecondary)
            }
        }
    }

    // MARK: - 5. Volume & Dynamics

    private var volumeOptionsSection: some View {
        VStack(spacing: 12) {
            // 볼륨 슬라이더
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("볼륨")
                        .font(.system(size: 11, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(1.0)
                        .foregroundStyle(MatutaTheme.textSecondary)

                    Spacer()

                    Text("\(Int(alarm.volume * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(MatutaTheme.textPrimary)
                }

                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(MatutaTheme.textSecondary)

                    Slider(value: $alarm.volume, in: 0...1)
                        .tint(MatutaTheme.primaryAccent)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(MatutaTheme.textSecondary)
                }
            }

            Divider().opacity(0.15)

            // 토글 옵션들
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("서서히 커지기 (점진적 페이드인)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MatutaTheme.textPrimary)
                    Text("낮은 볼륨에서 설정 볼륨까지 30초간 부드럽게 상승")
                        .font(.system(size: 10))
                        .foregroundStyle(MatutaTheme.textTertiary)
                }
                Spacer()
                MatutaToggle(isOn: $alarm.fadeIn)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("스누즈 (9분)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MatutaTheme.textPrimary)
                    Text("알람 울릴 때 9분 뒤 다시 울림 허용")
                        .font(.system(size: 10))
                        .foregroundStyle(MatutaTheme.textTertiary)
                }
                Spacer()
                MatutaToggle(isOn: Binding(
                    get: { alarm.snoozeMinutes != nil },
                    set: { alarm.snoozeMinutes = $0 ? 9 : nil }
                ))
            }
        }
        .padding(14)
        .background(MatutaTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(MatutaTheme.subtleStroke, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func presetChip(_ title: String, text: String) -> some View {
        Button(action: {
            spotifyInput = text
            syncAlarmSource()
        }) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MatutaTheme.textSecondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func webPresetChip(_ title: String, url: String) -> some View {
        Button(action: {
            webInput = url
            syncAlarmSource()
        }) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MatutaTheme.textSecondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func radioPresetChip(_ title: String, url: String) -> some View {
        Button(action: {
            radioInput = url
            syncAlarmSource()
        }) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MatutaTheme.textSecondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
