import SwiftUI
import AppKit

// MARK: - Matuta Cozy & Warm Design System

public enum CozyTheme: String, CaseIterable, Identifiable, Sendable {
    case midnight = "아늑한 밤 (모닥불)"
    case oat = "오트밀 (따뜻한 우유)"
    case matcha = "말차 (아침 숲)"
    case sunset = "선셋 (노을빛 복숭아)"
    case lavender = "라벤더 (새벽 구름)"
    case cedar = "원목 (드립 커피)"

    public var id: String { rawValue }

    public var isLight: Bool {
        self == .oat
    }

    public var themeIcon: String {
        switch self {
        case .midnight: return "flame.fill"
        case .oat:      return "cup.and.saucer.fill"
        case .matcha:   return "leaf.fill"
        case .sunset:   return "sun.horizon.fill"
        case .lavender: return "moon.stars.fill"
        case .cedar:    return "tree.fill"
        }
    }

    public var baseBackground: Color {
        switch self {
        case .midnight: return Color(red: 0.09, green: 0.08, blue: 0.08)  // #171414
        case .oat:      return Color(red: 0.98, green: 0.97, blue: 0.95)  // #FAF7F2
        case .matcha:   return Color(red: 0.07, green: 0.10, blue: 0.08)  // #121A14
        case .sunset:   return Color(red: 0.11, green: 0.08, blue: 0.10)  // #1C141A
        case .lavender: return Color(red: 0.09, green: 0.08, blue: 0.13)  // #171421
        case .cedar:    return Color(red: 0.10, green: 0.08, blue: 0.07)  // #1A1412
        }
    }

    public var cardBackground: Color {
        switch self {
        case .midnight: return Color(red: 0.14, green: 0.12, blue: 0.12)  // #241F1F
        case .oat:      return Color(red: 0.93, green: 0.91, blue: 0.87)  // #EDE8DE
        case .matcha:   return Color(red: 0.11, green: 0.15, blue: 0.12)  // #1C261F
        case .sunset:   return Color(red: 0.16, green: 0.12, blue: 0.15)  // #291F26
        case .lavender: return Color(red: 0.14, green: 0.12, blue: 0.19)  // #241F30
        case .cedar:    return Color(red: 0.15, green: 0.12, blue: 0.10)  // #261F1A
        }
    }

    public var cardBackgroundHover: Color {
        switch self {
        case .midnight: return Color(red: 0.17, green: 0.15, blue: 0.15)
        case .oat:      return Color(red: 0.89, green: 0.87, blue: 0.83)
        case .matcha:   return Color(red: 0.14, green: 0.19, blue: 0.15)
        case .sunset:   return Color(red: 0.20, green: 0.15, blue: 0.19)
        case .lavender: return Color(red: 0.18, green: 0.15, blue: 0.24)
        case .cedar:    return Color(red: 0.19, green: 0.15, blue: 0.13)
        }
    }

    public var accent: Color {
        switch self {
        case .midnight: return Color(red: 0.96, green: 0.62, blue: 0.20)  // Warm flame amber
        case .oat:      return Color(red: 0.82, green: 0.45, blue: 0.22)  // Caramel terracotta
        case .matcha:   return Color(red: 0.38, green: 0.70, blue: 0.48)  // Matcha sage
        case .sunset:   return Color(red: 0.92, green: 0.48, blue: 0.42)  // Peach coral
        case .lavender: return Color(red: 0.68, green: 0.55, blue: 0.95)  // Cozy lilac
        case .cedar:    return Color(red: 0.85, green: 0.55, blue: 0.32)  // Honey cinnamon
        }
    }

    public var textPrimary: Color {
        isLight ? Color(red: 0.20, green: 0.18, blue: 0.16) : Color(red: 0.96, green: 0.94, blue: 0.92)
    }

    public var textSecondary: Color {
        isLight ? Color(red: 0.48, green: 0.44, blue: 0.40) : Color(red: 0.70, green: 0.67, blue: 0.64)
    }

    public var textTertiary: Color {
        isLight ? Color(red: 0.68, green: 0.64, blue: 0.60) : Color(red: 0.46, green: 0.43, blue: 0.40)
    }

    public var subtleStroke: Color {
        isLight ? Color.black.opacity(0.06) : Color.white.opacity(0.07)
    }

    public var highlightStroke: Color {
        isLight ? Color.black.opacity(0.12) : Color.white.opacity(0.15)
    }
}

// MARK: - Theme Manager (Global State & Persistence)

@MainActor
@Observable
public final class ThemeManager {
    public static let shared = ThemeManager()

    public var current: CozyTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "MatutaCozyTheme")
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "MatutaCozyTheme"),
           let theme = CozyTheme(rawValue: saved) {
            self.current = theme
        } else {
            self.current = .midnight
        }
    }
}

// MARK: - Custom Cozy Rounded Switch

struct CozyToggle: View {
    @Binding var isOn: Bool
    var accent: Color = ThemeManager.shared.current.accent

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isOn ? accent : (ThemeManager.shared.current.isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.12)))
                    .frame(width: 44, height: 26)

                Circle()
                    .fill(Color.white)
                    .padding(2.5)
                    .shadow(color: Color.black.opacity(0.18), radius: 2, y: 1)
            }
            .frame(width: 44, height: 26)
        }
        .buttonStyle(.plain)
    }
}
