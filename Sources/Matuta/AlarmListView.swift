import SwiftUI
import MatutaCore

struct AlarmListView: View {
    @Bindable var model: AlarmListModel

    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더
            headerView
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

            Divider()
                .opacity(0.12)

            // 알람 카드 갤러리
            if model.alarms.isEmpty {
                emptyStateView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(model.alarms) { alarm in
                            ArtisanAlarmCard(alarm: alarm) {
                                model.toggle(alarm)
                            } onEdit: {
                                model.editing = alarm
                            } onDelete: {
                                model.delete(alarm)
                            }
                        }
                    }
                    .padding(18)
                }
            }

            Divider()
                .opacity(0.12)

            // 하단 상태 및 액션 바
            footerView
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
        }
        .frame(minWidth: 400, maxWidth: 460, minHeight: 480, maxHeight: 640)
        .background(MatutaTheme.baseBackground)
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
                HStack(spacing: 6) {
                    Text("MATUTA")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2.5)
                        .foregroundStyle(MatutaTheme.textSecondary)

                    Circle()
                        .fill(MatutaTheme.neonGreen)
                        .frame(width: 5, height: 5)
                }

                if let next = model.nextFireDate {
                    Text("다음 알람 \(next.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(MatutaTheme.textPrimary)
                } else {
                    Text("켜진 알람 없음")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(MatutaTheme.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // 나이트스탠드 버튼
                Button(action: { model.openNightstand() }) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MatutaTheme.sunriseAmber)
                        .frame(width: 34, height: 34)
                        .background(MatutaTheme.cardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(MatutaTheme.subtleStroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("나이트스탠드 (전체화면 침대 시계)")

                // 새 알람 추가 버튼
                Button(action: { model.addAlarm() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 34, height: 34)
                        .background(MatutaTheme.primaryAccent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("새 알람 만들기")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "alarm")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(MatutaTheme.textTertiary)

            Text("설정된 알람이 없습니다")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MatutaTheme.textSecondary)

            Button(action: { model.addAlarm() }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("첫 알람 만들기")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var footerView: some View {
        HStack {
            Text("\(model.alarms.count) ALARMS SCHEDULED")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(MatutaTheme.textTertiary)

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
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(Capsule())
                .shadow(color: Color.white.opacity(0.15), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 장인 수준의 아티잔 알람 카드

private struct ArtisanAlarmCard: View {
    let alarm: Alarm
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center, spacing: 14) {
                // 시간 및 메타데이터
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(timeNumberString)
                            .font(.system(size: 38, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(alarm.isEnabled ? MatutaTheme.textPrimary : MatutaTheme.textTertiary)

                        Text(periodString)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(alarm.isEnabled ? MatutaTheme.textSecondary : MatutaTheme.textTertiary)
                    }

                    // 요일 미니 인디케이터
                    HStack(spacing: 3.5) {
                        ForEach(Weekday.displayOrder, id: \.self) { day in
                            let isActive = alarm.weekdays.contains(day)
                            Text(day.shortName)
                                .font(.system(size: 9, weight: isActive ? .bold : .medium))
                                .frame(width: 18, height: 18)
                                .background(isActive ? (alarm.isEnabled ? MatutaTheme.primaryAccent : Color.white.opacity(0.15)) : Color.clear)
                                .foregroundStyle(isActive ? Color.white : MatutaTheme.textTertiary)
                                .clipShape(Circle())
                        }

                        if alarm.weekdays.isEmpty {
                            Text("1회성")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(MatutaTheme.textTertiary)
                                .padding(.leading, 4)
                        }
                    }

                    // 라벨 및 소스 뱃지
                    HStack(spacing: 6) {
                        if let label = alarm.label, !label.isEmpty {
                            Text(label)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(MatutaTheme.textPrimary)
                        }

                        sourcePill
                    }
                }

                Spacer()

                // 커스텀 정밀 토글 스위치
                MatutaToggle(isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { _ in onToggle() }
                ))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isHovered ? MatutaTheme.cardBackgroundHover : MatutaTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isHovered ? MatutaTheme.highlightStroke : MatutaTheme.subtleStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.35 : 0.15), radius: isHovered ? 10 : 4, y: 2)
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

    private var sourcePill: some View {
        HStack(spacing: 4) {
            sourceIcon
                .font(.system(size: 9))
            Text(sourceName)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .foregroundStyle(MatutaTheme.textSecondary)
    }

    @ViewBuilder
    private var sourceIcon: some View {
        switch alarm.source {
        case .builtIn:
            Image(systemName: "bell.fill").foregroundStyle(MatutaTheme.sunriseAmber)
        case .localFile:
            Image(systemName: "music.note").foregroundStyle(MatutaTheme.electricCyan)
        case .streamURL:
            Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(MatutaTheme.sunriseOrange)
        case .appleMusic:
            Image(systemName: "apple.logo").foregroundStyle(MatutaTheme.sunsetPink)
        case .spotify:
            Image(systemName: "waveform").foregroundStyle(MatutaTheme.neonGreen)
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
