import SwiftUI
import AppKit

// MARK: - Matuta Artisan Design System ("Aura & Precision")

public enum MatutaTheme {
    // Backgrounds
    public static let baseBackground = Color(red: 0.05, green: 0.06, blue: 0.08)
    public static let cardBackground = Color(red: 0.10, green: 0.11, blue: 0.15)
    public static let cardBackgroundHover = Color(red: 0.13, green: 0.15, blue: 0.20)
    public static let elevatedSurface = Color(red: 0.16, green: 0.18, blue: 0.24)

    // Accents & Gradients
    public static let sunriseOrange = Color(red: 1.0, green: 0.42, blue: 0.28)
    public static let sunriseAmber = Color(red: 1.0, green: 0.68, blue: 0.32)
    public static let electricCyan = Color(red: 0.22, green: 0.82, blue: 1.0)
    public static let neonGreen = Color(red: 0.20, green: 0.88, blue: 0.55)
    public static let sunsetPink = Color(red: 0.98, green: 0.35, blue: 0.62)
    public static let primaryAccent = Color(red: 0.38, green: 0.55, blue: 1.0)

    // Borders & Strokes
    public static let subtleStroke = Color.white.opacity(0.08)
    public static let highlightStroke = Color.white.opacity(0.18)

    // Text Colors
    public static let textPrimary = Color.white.opacity(0.95)
    public static let textSecondary = Color.white.opacity(0.60)
    public static let textTertiary = Color.white.opacity(0.35)
}

// MARK: - Tactile Hover Card Modifier

struct MatutaCardModifier: ViewModifier {
    var isHovered: Bool
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isHovered ? MatutaTheme.cardBackgroundHover : MatutaTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(isHovered ? MatutaTheme.highlightStroke : MatutaTheme.subtleStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.35 : 0.15), radius: isHovered ? 12 : 6, y: isHovered ? 6 : 2)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
    }
}

extension View {
    func matutaCard(isHovered: Bool = false, cornerRadius: CGFloat = 16) -> some View {
        self.modifier(MatutaCardModifier(isHovered: isHovered, cornerRadius: cornerRadius))
    }
}

// MARK: - Custom Precision Switch

struct MatutaToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isOn ? MatutaTheme.primaryAccent : Color.white.opacity(0.12))
                    .frame(width: 42, height: 24)

                Circle()
                    .fill(Color.white)
                    .padding(2.5)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            }
            .frame(width: 42, height: 24)
        }
        .buttonStyle(.plain)
    }
}
