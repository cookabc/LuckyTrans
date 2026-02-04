import SwiftUI
import AppKit

// MARK: - LuckyTrans Design System
// Centralized design tokens for consistent UI across the app

enum LTDesign {
    
    // MARK: - Colors
    enum Colors {
        // Primary gradient (blue to purple)
        static let primaryGradient = LinearGradient(
            colors: [Color.blue, Color.purple.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        // Accent bar gradient (lighter version for title bars)
        static let accentGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.7),
                Color.purple.opacity(0.6)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        // Surface colors
        static func surface(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark 
                ? Color(nsColor: .windowBackgroundColor)
                : Color.white
        }
        
        // Text colors
        static func primaryText(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? .white : .black
        }
        
        static func secondaryText(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark 
                ? Color.white.opacity(0.7)
                : Color.black.opacity(0.6)
        }
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Border colors
        static let subtleBorder = Color.secondary.opacity(0.2)
        static let accentBorder = Color.blue.opacity(0.3)
    }
    
    // MARK: - Typography
    enum Typography {
        // Title styles
        static let windowTitle = Font.system(size: 14, weight: .semibold)
        static let sectionTitle = Font.system(size: 13, weight: .semibold)
        static let settingsTitle = Font.title2.weight(.bold)
        
        // Body styles
        static let body = Font.system(size: 14)
        static let bodyLarge = Font.system(size: 16)
        static let caption = Font.system(size: 12)
        static let captionSmall = Font.system(size: 11)
        
        // Translation specific
        static let originalText = Font.system(size: 14).italic()
        static let translatedText = Font.system(size: 16, weight: .medium)
        
        // Key display (for shortcut recorder)
        static let keyDisplay = Font.system(size: 24, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 12
        static let xlarge: CGFloat = 16
    }
    
    // MARK: - Shadows
    enum Shadows {
        static func card(for colorScheme: ColorScheme) -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.xlarge)
                .shadow(
                    color: colorScheme == .dark 
                        ? Color.black.opacity(0.3) 
                        : Color.black.opacity(0.1),
                    radius: 15,
                    x: 0,
                    y: 5
                )
        }
        
        static func subtle(for colorScheme: ColorScheme) -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .shadow(
                    color: colorScheme == .dark 
                        ? Color.black.opacity(0.2) 
                        : Color.black.opacity(0.05),
                    radius: 5,
                    x: 0,
                    y: 2
                )
        }
    }
    
    // MARK: - Animations
    enum Animation {
        // Window animations
        static let windowAppear = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.8)
        static let windowDisappear = SwiftUI.Animation.easeIn(duration: 0.15)
        
        // Button interactions
        static let buttonHover = SwiftUI.Animation.easeOut(duration: 0.1)
        static let buttonPress = SwiftUI.Animation.easeOut(duration: 0.1)
        
        // Content transitions
        static let contentFade = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let pulse = SwiftUI.Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        
        // Durations (in seconds)
        static let durationFast: Double = 0.1
        static let durationNormal: Double = 0.2
        static let durationSlow: Double = 0.3
        static let copyFeedbackDuration: Double = 1.0
    }
    
    // MARK: - Window Sizes
    enum WindowSize {
        static let floatingWindow = CGSize(width: 450, height: 300)
        static let settingsWindow = CGSize(width: 600, height: 500)
        static let shortcutRecorder = CGSize(width: 400, height: 250)
        static let permissionGuide = CGSize(width: 400, height: 350)
    }
}

// MARK: - View Modifiers

/// Glass morphism background modifier
struct GlassMorphismBackground: ViewModifier {
    let colorScheme: ColorScheme
    let cornerRadius: CGFloat
    let showBorder: Bool
    
    init(colorScheme: ColorScheme, cornerRadius: CGFloat = LTDesign.CornerRadius.xlarge, showBorder: Bool = true) {
        self.colorScheme = colorScheme
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LTDesign.Colors.surface(for: colorScheme))
                    
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(LTDesign.Colors.subtleBorder, lineWidth: 0.5)
                    }
                }
                .shadow(
                    color: colorScheme == .dark 
                        ? Color.black.opacity(0.3) 
                        : Color.black.opacity(0.1),
                    radius: 15,
                    x: 0,
                    y: 5
                )
            )
    }
}

/// Settings card background modifier
struct SettingsCardBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: LTDesign.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: LTDesign.CornerRadius.large)
                    .stroke(LTDesign.Colors.subtleBorder, lineWidth: 0.5)
            )
    }
}

/// Hover effect modifier for buttons
struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small)
                    .fill(Color.primary.opacity(isHovered ? 0.1 : 0))
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(LTDesign.Animation.buttonHover, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

/// Press effect modifier for buttons
struct PressEffectModifier: ViewModifier {
    @GestureState private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(LTDesign.Animation.buttonPress, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass morphism background
    func glassMorphism(colorScheme: ColorScheme, cornerRadius: CGFloat = LTDesign.CornerRadius.xlarge, showBorder: Bool = true) -> some View {
        modifier(GlassMorphismBackground(colorScheme: colorScheme, cornerRadius: cornerRadius, showBorder: showBorder))
    }
    
    /// Apply settings card background
    func settingsCard() -> some View {
        modifier(SettingsCardBackground())
    }
    
    /// Apply hover effect
    func hoverEffect() -> some View {
        modifier(HoverEffectModifier())
    }
    
    /// Apply press effect
    func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }
}

// MARK: - Reusable Components

/// Gradient accent bar for window headers
struct AccentBar: View {
    var width: CGFloat = 40
    var height: CGFloat = 4
    
    var body: some View {
        Capsule()
            .fill(LTDesign.Colors.accentGradient)
            .frame(width: width, height: height)
    }
}

/// Key cap display for shortcut recorder
struct KeyCap: View {
    let key: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text(key)
            .font(LTDesign.Typography.keyDisplay)
            .foregroundStyle(LTDesign.Colors.primaryText(for: colorScheme))
            .frame(minWidth: 50, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: LTDesign.CornerRadius.medium)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LTDesign.CornerRadius.medium)
                    .stroke(LTDesign.Colors.subtleBorder, lineWidth: 1)
            )
    }
}

/// Instruction row for permission guide
struct InstructionRow: View {
    let number: Int
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: LTDesign.Spacing.md) {
            Text("\(number).")
                .font(LTDesign.Typography.body.weight(.semibold))
                .foregroundStyle(LTDesign.Colors.primaryText(for: colorScheme))
            
            Text(text)
                .font(LTDesign.Typography.body)
                .foregroundStyle(LTDesign.Colors.secondaryText(for: colorScheme))
            
            Spacer()
        }
        .padding(.vertical, LTDesign.Spacing.sm)
        .padding(.horizontal, LTDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small)
                .fill(colorScheme == .dark 
                    ? Color.white.opacity(0.05) 
                    : Color.black.opacity(0.03))
        )
    }
}

/// Copy button with feedback animation
struct CopyButtonWithFeedback: View {
    let textToCopy: String
    @State private var showCopied = false
    
    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(textToCopy, forType: .string)
            
            withAnimation {
                showCopied = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + LTDesign.Animation.copyFeedbackDuration) {
                withAnimation {
                    showCopied = false
                }
            }
        } label: {
            HStack(spacing: LTDesign.Spacing.xxs) {
                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                Text(showCopied ? "已复制" : "复制")
            }
            .font(LTDesign.Typography.caption)
        }
        .buttonStyle(.bordered)
        .tint(showCopied ? .green : nil)
        .animation(.easeInOut(duration: 0.2), value: showCopied)
    }
}

/// Menu bar header view with brand identity
struct MenuBarHeaderView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var body: some View {
        HStack(spacing: LTDesign.Spacing.md) {
            // App Icon
            ZStack {
                Circle()
                    .fill(LTDesign.Colors.primaryGradient)
                    .frame(width: 28, height: 28)
                
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("LuckyTrans")
                    .font(.system(size: 13, weight: .semibold))
                
                Text("v\(appVersion)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, LTDesign.Spacing.md)
        .padding(.vertical, LTDesign.Spacing.sm)
    }
}
