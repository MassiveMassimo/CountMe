import SwiftUI

// Extension to add Tailwind gray palette to SwiftUI Color
extension Color {
    // MARK: - Gray palette (static colors)
    static let gray50 = Color(hex: 0xf9fafb)
    static let gray100 = Color(hex: 0xf3f4f6)
    static let gray200 = Color(hex: 0xe5e7eb)
    static let gray300 = Color(hex: 0xd1d5db)
    static let gray400 = Color(hex: 0x9ca3af)
    static let gray500 = Color(hex: 0x6b7280)
    static let gray600 = Color(hex: 0x4b5563)
    static let gray700 = Color(hex: 0x374151)
    static let gray800 = Color(hex: 0x1f2937)
    static let gray900 = Color(hex: 0x111827)
    static let gray950 = Color(hex: 0x030712)
    
    // MARK: - Semantic gray colors (auto light/dark adaptation)
    
    // Background colors
    static let grayBackground = Color.adaptive(light: .gray100, dark: .gray900)
    static let grayBackgroundSecondary = Color.adaptive(light: .gray50, dark: .gray800)
    
    // Surface colors (for cards, modals, etc.)
    static let graySurface = Color.adaptive(light: .white, dark: .gray800)
    static let graySurfaceSecondary = Color.adaptive(light: .gray50, dark: .gray700)
    
    // Border and divider colors
    static let grayBorder = Color.adaptive(light: .gray200, dark: .gray700)
    static let grayDivider = Color.adaptive(light: .gray200, dark: .gray700)
    
    // Text colors
    static let grayText = Color.adaptive(light: .gray900, dark: .gray50)
    static let grayTextSecondary = Color.adaptive(light: .gray600, dark: .gray400)
    static let grayTextTertiary = Color.adaptive(light: .gray500, dark: .gray500)
    
    // Input and control colors
    static let grayInput = Color.adaptive(light: .gray100, dark: .gray700)
    static let grayInputFocused = Color.adaptive(light: .gray200, dark: .gray600)
    static let grayPlaceholder = Color.adaptive(light: .gray400, dark: .gray500)
    
    // Helper for adaptive colors
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    // Initialize color from hex value
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Usage examples

struct TailwindGrayExample: View {
    var body: some View {
        ZStack {
            // Main background (like bg-gray-100 dark:bg-gray-900)
            Color.grayBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Tailwind Gray Palette")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.grayText)
                    
                    // Static color examples
                    staticColorGrid
                    
                    // Card example
                    cardExample
                    
                    // Text color examples
                    textExample
                }
                .padding()
            }
        }
    }
    
    // Static color grid
    private var staticColorGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Static Colors")
                .font(.headline)
                .foregroundStyle(Color.grayText)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                colorTile("50", color: .gray50)
                colorTile("100", color: .gray100)
                colorTile("200", color: .gray200)
                colorTile("300", color: .gray300)
                colorTile("400", color: .gray400)
                colorTile("500", color: .gray500)
                colorTile("600", color: .gray600)
                colorTile("700", color: .gray700)
                colorTile("800", color: .gray800)
                colorTile("900", color: .gray900)
                colorTile("950", color: .gray950)
            }
        }
    }
    
    // Card example using adaptive colors
    private var cardExample: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card Example")
                .font(.headline)
                .foregroundStyle(Color.grayText)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Title")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.grayText)
                
                Text("This is a card example using Tailwind-inspired colors that automatically adapt between light and dark mode.")
                    .foregroundStyle(Color.grayTextSecondary)
                
                Divider()
                    .background(Color.grayDivider)
                
                HStack(spacing: 8) {
                    chipView(text: "Design")
                    chipView(text: "SwiftUI")
                    chipView(text: "Colors")
                }
            }
            .padding()
            .background(Color.graySurface)
            .cornerRadius(12)
            .shadow(color: Color.grayText.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // Text example
    private var textExample: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text Colors")
                .font(.headline)
                .foregroundStyle(Color.grayText)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Primary Text")
                    .foregroundStyle(Color.grayText)
                
                Text("Secondary Text")
                    .foregroundStyle(Color.grayTextSecondary)
                
                Text("Tertiary Text")
                    .foregroundStyle(Color.grayTextTertiary)
                
                Text("Placeholder")
                    .foregroundStyle(Color.grayPlaceholder)
            }
            .padding()
            .background(Color.graySurfaceSecondary)
            .cornerRadius(8)
        }
    }
    
    // Helper to create a color tile
    private func colorTile(_ label: String, color: Color) -> some View {
        VStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.grayBorder, lineWidth: 1)
                )
            
            Text("Gray-\(label)")
                .font(.caption)
                .foregroundStyle(Color.grayTextSecondary)
        }
    }
    
    // Helper to create a chip view
    private func chipView(text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.grayInput)
            .foregroundStyle(Color.grayTextSecondary)
            .cornerRadius(16)
    }
}

#Preview {
    TailwindGrayExample()
}
