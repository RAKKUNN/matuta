import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MatutaCore

struct SoundOmniboxView: View, Localizable {
    @Binding var soundRef: SoundSourceRef
    let theme: CozyTheme
    @Environment(LanguageSetting.self) var language

    @State private var omniboxText: String = ""
    @State private var isShowingBrowseDrawer: Bool = false
    @State private var isDropTargeted: Bool = false
    @State private var isPreviewing: Bool = false
    @State private var previewPlayer = TonePlayer()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 헤더
            HStack {
                Text(t(.wakeSoundPrompt))
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
                        Text(isShowingBrowseDrawer ? t(.collapse) : t(.browseTonesAndFiles))
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

                TextField(t(.omniboxPlaceholder), text: $omniboxText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textPrimary)
                    .onChange(of: omniboxText) { _, newText in
                        guard !newText.isEmpty else { return }
                        let parsed = OmniboxParser.parse(text: newText)
                        self.soundRef = parsed
                    }

                if let clipboard = NSPasteboard.general.string(forType: .string), !clipboard.isEmpty && clipboard != omniboxText {
                    Button(t(.paste)) {
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

            if case .builtIn(let tone) = soundRef {
                Button(action: { toggleBuiltInPreview(tone: tone) }) {
                    HStack(spacing: 4) {
                        Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                            .font(.system(size: 9))
                        Text(isPreviewing ? t(.stop) : t(.preview))
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
            presetChip("Morning Harp", source: .builtIn(.morningHarp), icon: "bell.fill")
            presetChip("Warm Rhodes", source: .builtIn(.warmRhodes), icon: "bell.fill")
            presetChip(t(.lofiGirlWeb), source: .web(URL(string: "https://www.youtube.com/watch?v=jfKfPfyJRdk")!), icon: "play.rectangle.fill")
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
                Text(t(.builtInToneColon))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)

                Picker("", selection: Binding(
                    get: {
                        if case .builtIn(let tone) = soundRef { return tone }
                        return .default
                    },
                    set: { newTone in
                        self.soundRef = .builtIn(newTone)
                        self.omniboxText = ""
                    }
                )) {
                    ForEach(BuiltInTone.allCases, id: \.self) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Button(t(.chooseLocalFile)) {
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
        case .builtIn: return t(.builtInTones)
        case .localFile: return t(.localAudioFile)
        case .streamURL: return t(.streamRadio)
        case .appleMusic: return t(.appleMusic)
        case .spotify: return t(.spotifyWithBackup)
        case .web: return t(.webWithBackup)
        }
    }

    private var sourceDetailTitle: String {
        switch soundRef {
        case .builtIn(let tone):
            return tone.rawValue
        case .localFile(let bookmark):
            if let url = LocalFileSource.resolve(bookmark: bookmark) {
                return url.lastPathComponent
            }
            return t(.localAudioFile)
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

    private func toggleBuiltInPreview(tone: BuiltInTone) {
        if isPreviewing {
            stopPreview()
        } else {
            isPreviewing = true
            let pattern = TonePattern.pattern(for: tone)
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
