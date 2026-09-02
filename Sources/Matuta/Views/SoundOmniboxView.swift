import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MatutaCore

struct SoundOmniboxView: View {
    @Binding var soundRef: SoundSourceRef
    let theme: CozyTheme

    @State private var omniboxText: String = ""
    @State private var isShowingBrowseDrawer: Bool = false
    @State private var isDropTargeted: Bool = false
    @State private var isPreviewing: Bool = false
    @State private var previewPlayer = TonePlayer()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 헤더
            HStack {
                Text("무엇으로 깨울까요")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.textSecondary)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingBrowseDrawer.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isShowingBrowseDrawer ? "chevron.up" : "folder.fill")
                            .font(.system(size: 10))
                        Text(isShowingBrowseDrawer ? "접기" : "벨소리 / 파일 찾아보기")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(theme.accent)
                }
                .buttonStyle(.plain)
            }

            // 1. 옴니박스 스마트 입력창
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textTertiary)

                TextField("Spotify 링크, YouTube URL, 라디오 주소 또는 파일 경로", text: $omniboxText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textPrimary)
                    .onChange(of: omniboxText) { _, newText in
                        guard !newText.isEmpty else { return }
                        let parsed = OmniboxParser.parse(text: newText)
                        self.soundRef = parsed
                    }

                if let clipboard = NSPasteboard.general.string(forType: .string), !clipboard.isEmpty && clipboard != omniboxText {
                    Button("붙여넣기") {
                        omniboxText = clipboard
                        self.soundRef = OmniboxParser.parse(text: clipboard)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.accent)
                }
            }
            .padding(10)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isDropTargeted ? theme.accent : theme.subtleStroke, lineWidth: 1)
            )
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleFileDrop(providers)
            }

            // 2. 현재 선택된 소스 배지 (확정 칩)
            activeSourceBanner

            // 3. 추천 프리셋 칩들
            recommendedChipsSection

            // 4. 확장 서랍: 내장 사운드스케이프 & 로컬 파일 선택기
            if isShowingBrowseDrawer {
                browseDrawerSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            initializeOmniboxText()
        }
        .onDisappear {
            stopPreview()
        }
    }

    // MARK: - Active Source Banner

    private var activeSourceBanner: some View {
        HStack(spacing: 8) {
            sourceIcon
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.accent)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(sourceCategoryTitle)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.accent)
                    Text("·")
                        .foregroundStyle(theme.textTertiary)
                    Text(sourceDetailTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if case .builtIn(let name) = soundRef {
                Button(action: { toggleBuiltInPreview(name: name) }) {
                    HStack(spacing: 4) {
                        Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                            .font(.system(size: 9))
                        Text(isPreviewing ? "정지" : "미리듣기")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(isPreviewing ? Color.white : theme.textPrimary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(isPreviewing ? theme.accent : (theme.isLight ? Color.black.opacity(0.06) : Color.white.opacity(0.1)))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(theme.isLight ? Color.black.opacity(0.03) : Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Recommended Chips

    private var recommendedChipsSection: some View {
        HStack(spacing: 6) {
            presetChip("Morning Harp", source: .builtIn(name: "Morning Harp"), icon: "bell.fill")
            presetChip("Warm Rhodes", source: .builtIn(name: "Warm Rhodes"), icon: "bell.fill")
            presetChip("Lofi Girl (웹)", source: .web(URL(string: "https://www.youtube.com/watch?v=jfKfPfyJRdk")!), icon: "play.rectangle.fill")
            presetChip("Spotify Top 50", source: .spotify(uri: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M"), icon: "waveform")
        }
    }

    private func presetChip(_ title: String, source: SoundSourceRef, icon: String) -> some View {
        Button(action: {
            self.soundRef = source
            self.omniboxText = ""
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(theme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.cardBackground)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(theme.subtleStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Browse Drawer

    private var browseDrawerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("내장 벨소리:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)

                Picker("", selection: Binding(
                    get: {
                        if case .builtIn(let name) = soundRef { return name }
                        return "Morning Harp"
                    },
                    set: { newName in
                        self.soundRef = .builtIn(name: newName)
                        self.omniboxText = ""
                    }
                )) {
                    ForEach(TonePattern.allBuiltInNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Button("로컬 파일 선택...") {
                    selectLocalFile()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4.5)
                .background(theme.accent)
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(theme.subtleStroke, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    @ViewBuilder
    private var sourceIcon: some View {
        switch soundRef {
        case .builtIn:
            Image(systemName: "bell.fill")
        case .localFile:
            Image(systemName: "music.note")
        case .streamURL:
            Image(systemName: "antenna.radiowaves.left.and.right")
        case .appleMusic:
            Image(systemName: "apple.logo")
        case .spotify:
            Image(systemName: "waveform")
        case .web:
            Image(systemName: "play.rectangle.fill")
        }
    }

    private var sourceCategoryTitle: String {
        switch soundRef {
        case .builtIn: return "내장 사운드스케이프"
        case .localFile: return "로컬 음악 파일"
        case .streamURL: return "라디오 스트림"
        case .appleMusic: return "Apple Music"
        case .spotify: return "Spotify (백업음 보호)"
        case .web: return "웹 스트림 (백업음 보호)"
        }
    }

    private var sourceDetailTitle: String {
        switch soundRef {
        case .builtIn(let name):
            return name
        case .localFile(let bookmark):
            if let url = LocalFileSource.resolve(bookmark: bookmark) {
                return url.lastPathComponent
            }
            return "음악 파일"
        case .streamURL(let url):
            return url.host ?? url.absoluteString
        case .appleMusic(let id):
            return id
        case .spotify(let uri):
            return uri
        case .web(let url):
            return url.host ?? url.absoluteString
        }
    }

    private func toggleBuiltInPreview(name: String) {
        if isPreviewing {
            stopPreview()
        } else {
            isPreviewing = true
            let pattern = TonePattern.pattern(named: name)
            previewPlayer.start(pattern: pattern, volume: 0.8, fadeIn: false)
        }
    }

    private func stopPreview() {
        if isPreviewing {
            previewPlayer.stop()
            isPreviewing = false
        }
    }

    private func initializeOmniboxText() {
        switch soundRef {
        case .spotify(let uri): omniboxText = uri
        case .web(let url): omniboxText = url.absoluteString
        case .streamURL(let url): omniboxText = url.absoluteString
        default: break
        }
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            DispatchQueue.main.async {
                self.soundRef = OmniboxParser.makeLocalFileRef(for: url)
                self.omniboxText = url.lastPathComponent
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
            self.soundRef = OmniboxParser.makeLocalFileRef(for: url)
            self.omniboxText = url.lastPathComponent
        }
    }
}
