import SwiftUI
import MatutaCore

struct AlarmListView: View {
    @Bindable var model: AlarmListModel

    var body: some View {
        VStack(spacing: 0) {
            // 헤더 영역
            headerView
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .opacity(0.4)

            // 알람 목록 카드 뷰
            if model.alarms.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(model.alarms) { alarm in
                            AlarmCard(alarm: alarm) {
                                model.toggle(alarm)
                            } onEdit: {
                                model.editing = alarm
                            } onDelete: {
                                model.delete(alarm)
                            }
                        }
                    }
                    .padding(16)
                }
            }

            Divider()
                .opacity(0.4)

            // 하단 액션 바
            footerView
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .frame(minWidth: 380, maxWidth: 440, minHeight: 460, maxHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
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

    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("알람")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                if let next = model.nextFireDate {
                    Text("다음 알람: \(next.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text("켜진 알람 없음")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()

            HStack(spacing: 8) {
                Button(action: { model.openNightstand() }) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.yellow.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("나이트스탠드 (전체화면 침대 시계 모드)")

                Button(action: { model.addAlarm() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("새 알람 추가")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            Text("등록된 알람이 없습니다")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Button("첫 알람 만들기") {
                model.addAlarm()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 4)
            Spacer()
        }
    }

    private var footerView: some View {
        HStack {
            Text("\(model.alarms.count)개의 알람")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.tertiary)
            Spacer()
            Button(action: { model.addAlarm() }) {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("알람 추가")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 미니멀 모던 알람 카드 컴포넌트

private struct AlarmCard: View {
    let alarm: Alarm
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center, spacing: 14) {
                // 시간 및 요일 정보
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(timeNumberString)
                            .font(.system(size: 36, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(alarm.isEnabled ? .primary : .tertiary)

                        Text(periodString)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(alarm.isEnabled ? .secondary : .tertiary)
                    }

                    // 요일 미니 뱃지들
                    HStack(spacing: 3) {
                        ForEach(Weekday.displayOrder, id: \.self) { day in
                            let isActive = alarm.weekdays.contains(day)
                            Text(day.shortName)
                                .font(.system(size: 9, weight: isActive ? .bold : .regular))
                                .frame(width: 17, height: 17)
                                .background(isActive ? (alarm.isEnabled ? Color.accentColor : Color.secondary.opacity(0.3)) : Color.clear)
                                .foregroundStyle(isActive ? .white : Color.secondary.opacity(0.4))
                                .clipShape(Circle())
                        }

                        if alarm.weekdays.isEmpty {
                            Text("1회성")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                        }
                    }

                    // 라벨 및 소스 칩
                    HStack(spacing: 6) {
                        if let label = alarm.label, !label.isEmpty {
                            Text(label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.primary.opacity(0.8))
                        }

                        sourceBadge
                    }
                }

                Spacer()

                // 온/오프 토글 스위치
                Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: { _ in onToggle() }))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(isHovered ? 0.95 : 0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isHovered ? Color.primary.opacity(0.12) : Color.primary.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
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

    private var sourceBadge: some View {
        HStack(spacing: 4) {
            sourceIcon
                .font(.system(size: 9))
            Text(sourceName)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.12))
        .clipShape(Capsule())
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var sourceIcon: some View {
        switch alarm.source {
        case .builtIn:
            Image(systemName: "bell.fill").foregroundStyle(.yellow)
        case .localFile:
            Image(systemName: "music.note").foregroundStyle(.cyan)
        case .streamURL:
            Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(.orange)
        case .appleMusic:
            Image(systemName: "applelogo").foregroundStyle(.pink)
        case .spotify:
            Image(systemName: "waveform.circle.fill").foregroundStyle(.green)
        case .web:
            Image(systemName: "play.rectangle.fill").foregroundStyle(.red)
        }
    }

    private var sourceName: String {
        switch alarm.source {
        case .builtIn(let name):
            return name
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
}
