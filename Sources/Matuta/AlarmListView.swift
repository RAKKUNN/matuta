import SwiftUI
import MatutaCore

struct AlarmListView: View {
    @Bindable var model: AlarmListModel

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
                        }
                    }
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
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "alarms" || $0.title == "Matuta" || $0.title == "알람" }) {
                    window.center()
                }
            }
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
                    Text("다음 알람 \(next.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                } else {
                    Text("켜진 알람 없음")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // 테마 선택 메뉴 (6종 Cozy 테마)
                Menu {
                    ForEach(CozyTheme.allCases) { t in
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                ThemeManager.shared.current = t
                            }
                        } label: {
                            HStack {
                                Image(systemName: t.themeIcon)
                                Text(t.rawValue)
                                if ThemeManager.shared.current == t {
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
                .help("포근한 6종 테마 변경")

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
                .help("나이트스탠드 (전체화면 침대 시계)")

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
                .help("새 알람 만들기")
            }
        }
    }

    // MARK: - Cozy Quick Nap Bar

    private var quickNapBar: some View {
        HStack(spacing: 8) {
            quickNapChip(title: "20분 낮잠", minutes: 20, icon: "cup.and.saucer.fill")
            quickNapChip(title: "45분 집중", minutes: 45, icon: "book.fill")
            quickNapChip(title: "1시간 숙면", minutes: 60, icon: "moon.zzz.fill")
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

            Text("설정된 알람이 없습니다")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.textSecondary)

            Button(action: { model.addAlarm() }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("첫 알람 만들기")
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
        HStack {
            Text("\(model.alarms.count)개의 알람")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.textTertiary)

            Spacer()

            Button(action: { model.addAlarm() }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("알람 추가")
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
}

// MARK: - 아티잔 알람 카드 & 마이크로 인터랙션

private struct ArtisanAlarmCard: View {
    let alarm: Alarm
    let isSnoozing: Bool
    let snoozeUntil: Date?
    let onCancelSnooze: () -> Void
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

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
                        Text("스누즈 진행 중 · \(countdownText(to: until))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(theme.accent)

                    Spacer()

                    Button(action: onCancelSnooze) {
                        Text("취소")
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
                            Text(day.shortName)
                                .font(.system(size: 9, weight: isActive ? .bold : .medium))
                                .frame(width: 18, height: 18)
                                .background(isActive ? (alarm.isEnabled ? theme.accent : Color.gray.opacity(0.2)) : Color.clear)
                                .foregroundStyle(isActive ? Color.white : theme.textTertiary)
                                .clipShape(Circle())
                        }

                        if alarm.weekdays.isEmpty {
                            Text("1회성")
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
                    .help("알람 편집")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.red.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .background(theme.isLight ? Color.black.opacity(0.05) : Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("알람 삭제")
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
            Button("편집...") { onEdit() }
            Divider()
            Button("삭제", role: .destructive) { onDelete() }
        }
    }

    private var timeNumberString: String {
        let hour12 = alarm.hour == 0 ? 12 : (alarm.hour > 12 ? alarm.hour - 12 : alarm.hour)
        return String(format: "%d:%02d", hour12, alarm.minute)
    }

    private var periodString: String {
        alarm.hour < 12 ? "AM" : "PM"
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
            return "음악 파일"
        case .streamURL(let url):
            return url.host ?? "라디오"
        case .appleMusic:
            return "Apple Music"
        case .spotify:
            return "Spotify"
        case .web(let url):
            return url.host ?? "웹"
        }
    }

    private func countdownText(to date: Date) -> String {
        let diff = max(0, Int(date.timeIntervalSince(now)))
        let minutes = diff / 60
        let seconds = diff % 60
        return String(format: "%02d:%02d 남음", minutes, seconds)
    }
}
