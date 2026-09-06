import SwiftUI
import MatutaCore

struct AlarmListView: View, Localizable {
    @Bindable var model: AlarmListModel
    @Environment(LanguageSetting.self) var language
    @State private var preflightReport: PreflightReport?
    private let tick = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    private var theme: CozyTheme {
        ThemeManager.shared.current
    }

    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더
            headerView
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 12)

            // 포근한 퀵 파워냅 바
            quickNapBar
                .padding(.horizontal, 22)
                .padding(.bottom, 12)

            Divider()
                .opacity(theme.isLight ? 0.08 : 0.12)

            // 알람 카드 갤러리
            if model.alarms.isEmpty {
                emptyStateView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(model.alarms) { alarm in
                            let isSnoozing = model.snoozingAlarmID == alarm.id
                            ArtisanAlarmCard(
                                alarm: alarm,
                                isSnoozing: isSnoozing,
                                snoozeUntil: model.snoozeUntil,
                                onCancelSnooze: { model.cancelSnooze() },
                                onToggle: { model.toggle(alarm) },
                                onEdit: { model.editing = alarm },
                                onDelete: { model.delete(alarm) }
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                                removal: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                            ))
                        }
                    }
                    // save() 가 시각순 정렬을 하므로 편집만 해도 카드 위치가 바뀐다.
                    // 애니메이션이 없으면 방금 고친 카드가 어디로 갔는지 눈으로 쫓을 수 없다.
                    .animation(
                        .easeInOut(duration: MotionEnvironment.duration(.listChange)),
                        value: model.alarms
                    )
                    .padding(20)
                }
            }

            Divider()
                .opacity(theme.isLight ? 0.08 : 0.12)

            // 하단 상태 및 액션 바
            footerView
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
        }
        .frame(minWidth: 380, idealWidth: 460, maxWidth: .infinity, minHeight: 440, idealHeight: 620, maxHeight: .infinity)
        .background(theme.baseBackground)
        .onAppear {
            preflightReport = model.evaluatePreflight()
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "alarms" || $0.title == "Matuta" || $0.title == "알람" }) {
                    window.center()
                }
            }
        }
        .onReceive(tick) { _ in
            preflightReport = model.evaluatePreflight()
        }
        .sheet(item: $model.editing) { alarm in
            AlarmEditView(
                alarm: alarm,
                onSave: { updated in
                    model.save(updated)
                    model.editing = nil
                },
                onCancel: { model.editing = nil }
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    if let logoPath = Bundle.main.path(forResource: "logo", ofType: "png"),
                       let nsImage = NSImage(contentsOfFile: logoPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
                    }

                    Text("MATUTA")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2.5)
                        .foregroundStyle(theme.textSecondary)

                    Circle()
                        .fill(theme.accent)
                        .frame(width: 5, height: 5)
                }

                if let next = model.nextFireDate {
                    Text(t(.nextAlarmAt(next.formatted(.dateTime.hour().minute().locale(language.locale)))))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                } else {
                    Text(t(.noActiveAlarmsShort))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // 테마 선택 메뉴 (6종 Cozy 테마)
                Menu {
                    ForEach(CozyTheme.allCases) { tTheme in
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                ThemeManager.shared.current = tTheme
                            }
                        } label: {
                            HStack {
                                Image(systemName: tTheme.themeIcon)
                                Text(t(tTheme.localizedKey))
                                if ThemeManager.shared.current == tTheme {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.accent)
                        .frame(width: 34, height: 34)
                        .background(theme.cardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(theme.subtleStroke, lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 34, height: 34)

                // 나이트스탠드 버튼
                Button(action: { model.openNightstand() }) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.accent)
                        .frame(width: 34, height: 34)
                        .background(theme.cardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(theme.subtleStroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help(t(.nightstand))

                // 새 알람 추가 버튼
                Button(action: { model.addAlarm() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 34, height: 34)
                        .background(theme.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(t(.addAlarm))
            }
        }
    }

    // MARK: - Cozy Quick Nap Bar

    private var quickNapBar: some View {
        HStack(spacing: 8) {
            quickNapChip(title: t(.quickNap20), minutes: 20, icon: "cup.and.saucer.fill")
            quickNapChip(title: t(.quickNap45), minutes: 45, icon: "book.fill")
            quickNapChip(title: t(.quickNap60), minutes: 60, icon: "moon.zzz.fill")
            Spacer()
        }
    }

    private func quickNapChip(title: String, minutes: Int, icon: String) -> some View {
        Button(action: {
            addQuickNap(minutes: minutes, label: title)
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(theme.cardBackground)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(theme.subtleStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func addQuickNap(minutes: Int, label: String) {
        let target = Date().addingTimeInterval(Double(minutes) * 60)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: target)
        let minute = calendar.component(.minute, from: target)

        let alarm = Alarm(
            hour: hour,
            minute: minute,
            weekdays: [],
            label: label,
            source: .builtIn(.default),
            volume: 0.8,
            fadeIn: true,
            snoozeMinutes: 9,
            isEnabled: true
        )
        model.save(alarm)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "alarm")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(theme.textTertiary)

            Text(t(.noAlarms))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.textSecondary)

            Button(action: { model.addAlarm() }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text(t(.addAlarm))
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(theme.accent)
                .foregroundStyle(Color.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 12) {
            preflightStatusPill

            Spacer()

            Button(action: { model.addAlarm() }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text(t(.addAlarm))
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 7)
                .background(theme.accent)
                .foregroundStyle(Color.white)
                .clipShape(Capsule())
                .shadow(color: theme.accent.opacity(0.2), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var preflightStatusPill: some View {
        if let report = preflightReport {
            if let warning = report.primaryWarning {
                // 실제 문제(Warning)가 있을 때만 주황색 경고 + 원클릭 액션 노출 (§4 원칙 2)
                Button(action: {
                    handlePreflightAction(warning.kind)
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: warning.icon)
                        Text(warning.actionText != nil ? "\(t(warning.text)) → \(t(warning.actionText!))" : t(warning.text))
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(warning.actionText == nil)
            } else if let info = report.primaryInfo {
                // 단순 안내(Info, 예: 이어폰 연결): 문제 상태가 아니므로 중립적인 테마 색상으로 표시
                Button(action: {
                    handlePreflightAction(info.kind)
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: info.icon)
                        Text(info.actionText != nil ? "\(t(info.text)) → \(t(info.actionText!))" : t(info.text))
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(theme.cardBackground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(info.actionText == nil)
            } else {
                // 완전 정상
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.accent)
                    Text(t(.speakerStatus(volume: Int(report.audio.volume * 100))))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        } else {
            Text(t(.alarmCount(model.alarms.count)))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.textTertiary)
        }
    }

    private func handlePreflightAction(_ kind: PreflightWarning.Kind) {
        switch kind {
        case .headphones:
            model.switchToBuiltInSpeaker()
        case .muted, .lowVolume:
            model.setVolumeToSafeLevel(0.7)
        case .automationDenied:
            model.resolveAutomation()
        case .notLaunchAtLogin:
            model.enableLaunchAtLogin()
        case .wakeNotScheduled:
            break
        }
        preflightReport = model.evaluatePreflight()
    }
}

// MARK: - 아티잔 알람 카드 & 마이크로 인터랙션

private struct ArtisanAlarmCard: View, Localizable {
    let alarm: Alarm
    let isSnoozing: Bool
    let snoozeUntil: Date?
    let onCancelSnooze: () -> Void
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(LanguageSetting.self) var language

    @State private var isHovered = false
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var theme: CozyTheme {
        ThemeManager.shared.current
    }

    var body: some View {
        VStack(spacing: 8) {
            // 스누즈 진행 배지 (스누즈 중일 때 상단 표시)
            if isSnoozing, let until = snoozeUntil {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 10))
                        Text("\(t(.snoozing)) · \(countdownText(to: until))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(theme.accent)

                    Spacer()

                    Button(action: onCancelSnooze) {
                        Text(t(.cancel))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.isLight ? Color.black.opacity(0.06) : Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }

            HStack(alignment: .center, spacing: 14) {
                // 시간 및 메타데이터
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(timeNumberString)
                            .font(.system(size: 38, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(alarm.isEnabled ? theme.textPrimary : theme.textTertiary)

                        Text(periodString)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(alarm.isEnabled ? theme.textSecondary : theme.textTertiary)
                    }

                    // 요일 미니 인디케이터
                    HStack(spacing: 3.5) {
                        ForEach(Weekday.displayOrder, id: \.self) { day in
                            let isActive = alarm.weekdays.contains(day)
                            Text(t(day.shortNameText))
                                .font(.system(size: 9, weight: isActive ? .bold : .medium))
                                .fixedSize()
                                // 한국어는 "월" 한 글자, 영어는 "Mon" 세 글자다.
                                // 고정 폭으로 잡으면 M·W처럼 넓은 글자가 잘린다.
                                .padding(.horizontal, 5)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(isActive ? (alarm.isEnabled ? theme.accent : Color.gray.opacity(0.2)) : Color.clear)
                                .foregroundStyle(isActive ? Color.white : theme.textTertiary)
                                .clipShape(Capsule())
                        }

                        if alarm.weekdays.isEmpty {
                            Text(t(.once))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(theme.textTertiary)
                                .padding(.leading, 4)
                        }
                    }

                    // 라벨 및 소스 뱃지
                    HStack(spacing: 6) {
                        if let label = alarm.label, !label.isEmpty {
                            Text(label)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(theme.textPrimary)
                        }

                        sourcePill
                    }
                }

                Spacer()

                // 호버 시 노출되는 빠른 액션 버튼 (편집 & 삭제)
                HStack(spacing: 6) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                            .frame(width: 26, height: 26)
                            .background(theme.isLight ? Color.black.opacity(0.05) : Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(t(.editAlarm))

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.red.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .background(theme.isLight ? Color.black.opacity(0.05) : Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(t(.delete))
                }
                .opacity(isHovered ? 1 : 0)
                .animation(.easeInOut(duration: 0.18), value: isHovered)

                // 커스텀 Cozy 스위치
                CozyToggle(isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { _ in onToggle() }
                ), accent: theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isHovered ? theme.cardBackgroundHover : theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isSnoozing ? theme.accent.opacity(0.6) : (isHovered ? theme.highlightStroke : theme.subtleStroke), lineWidth: isSnoozing ? 1.5 : 1)
        )
        .shadow(color: Color.black.opacity(theme.isLight ? 0.04 : 0.2), radius: isHovered ? 8 : 3, y: 2)
        .onHover { isHovered = $0 }
        .onReceive(timer) { now = $0 }
        .contextMenu {
            Button(t(.edit)) { onEdit() }
            Divider()
            Button(t(.delete), role: .destructive) { onDelete() }
        }
    }

    private var timeNumberString: String {
        let hour12 = alarm.hour == 0 ? 12 : (alarm.hour > 12 ? alarm.hour - 12 : alarm.hour)
        return String(format: "%d:%02d", hour12, alarm.minute)
    }

    private var periodString: String {
        alarm.hour < 12 ? t(.am) : t(.pm)
    }

    private var sourcePill: some View {
        HStack(spacing: 4) {
            sourceIcon
                .font(.system(size: 9))
            Text(sourceName)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(theme.isLight ? Color.black.opacity(0.04) : Color.white.opacity(0.06))
        .clipShape(Capsule())
        .foregroundStyle(theme.textSecondary)
    }

    @ViewBuilder
    private var sourceIcon: some View {
        switch alarm.source {
        case .builtIn:
            Image(systemName: "bell.fill").foregroundStyle(theme.accent)
        case .localFile:
            Image(systemName: "music.note").foregroundStyle(theme.accent)
        case .streamURL:
            Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(theme.accent)
        case .appleMusic:
            Image(systemName: "apple.logo").foregroundStyle(theme.accent)
        case .spotify:
            Image(systemName: "waveform").foregroundStyle(theme.accent)
        case .web:
            Image(systemName: "play.rectangle.fill").foregroundStyle(theme.accent)
        }
    }

    private var sourceName: String {
        switch alarm.source {
        case .builtIn(let tone):
            return tone.rawValue
        case .localFile(let bookmark):
            if let url = LocalFileSource.resolve(bookmark: bookmark) {
                return url.lastPathComponent
            }
            return t(.localAudioFile)
        case .streamURL(let url):
            return url.host ?? t(.streamRadio)
        case .appleMusic:
            return "Apple Music"
        case .spotify:
            return "Spotify"
        case .web(let url):
            return url.host ?? t(.webAudio)
        }
    }

    private func countdownText(to date: Date) -> String {
        let diff = max(0, Int(date.timeIntervalSince(now)))
        let minutes = diff / 60
        let seconds = diff % 60
        return t(.remaining(String(format: "%02d:%02d", minutes, seconds)))
    }
}
