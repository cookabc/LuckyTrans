import AppKit
import SwiftUI
import AVFoundation

enum TranslationWindowState {
    case loading(String)
    case success(original: String, translation: String)
    case error(String)
}

class FloatingTranslationWindow: NSWindow {
    private var hostingView: NSHostingView<TranslationView>?
    private var autoCloseTask: DispatchWorkItem?
    private var initialFrame: NSRect = .zero

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)
        setupWindow()
    }
    
    private func setupWindow() {
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Apply current theme
        applyAppearance()
        
        // Set initial position (screen top-right, simplified)
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowSize = LTDesign.WindowSize.floatingWindow
            let x = screenRect.maxX - windowSize.width - 50
            let y = screenRect.maxY - windowSize.height - 100
            
            self.setFrame(NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height), display: true)
        }
    }
    
    private func applyAppearance() {
        let appearanceMode = SettingsManager.shared.appearanceMode
        let appearance: NSAppearance?
        switch appearanceMode {
        case .system:
            appearance = nil
        case .light:
            appearance = NSAppearance(named: .aqua)
        case .dark:
            appearance = NSAppearance(named: .darkAqua)
        }
        self.appearance = appearance ?? NSAppearance.currentDrawing()
    }
    
    func show(with state: TranslationWindowState) {
        // Cancel previous auto-close task
        autoCloseTask?.cancel()

        // Apply current theme
        applyAppearance()

        let translationView = TranslationView(state: state) { [weak self] in
            self?.closeWithAnimation()
        }

        if hostingView == nil {
            hostingView = NSHostingView(rootView: translationView)
            contentView = hostingView
        } else {
            hostingView?.rootView = translationView
        }

        // Position window near mouse
        if let screen = NSScreen.main {
            let mouse = NSEvent.mouseLocation
            let screenRect = screen.visibleFrame
            let windowSize = LTDesign.WindowSize.floatingWindow
            var x = mouse.x - windowSize.width / 2
            var y = mouse.y - windowSize.height - 16
            // Boundary constraints
            x = max(screenRect.minX + 8, min(x, screenRect.maxX - windowSize.width - 8))
            y = max(screenRect.minY + 8, min(y, screenRect.maxY - windowSize.height - 8))
            
            let targetFrame = NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height)
            initialFrame = targetFrame
            
            // Start slightly smaller for scale animation
            let startFrame = targetFrame.insetBy(dx: 15, dy: 15)
            setFrame(startFrame, display: false)
        }
        
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Enhanced entrance animation: Scale + Fade
        alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = LTDesign.Animation.durationNormal
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
            animator().setFrame(initialFrame, display: true)
        }

        // Auto-close after 30 seconds on success
        if case .success = state {
            let workItem = DispatchWorkItem { [weak self] in
                self?.closeWithAnimation()
            }
            autoCloseTask = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: workItem)
        }
    }
    
    func closeWithAnimation() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = LTDesign.Animation.durationFast + 0.05
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.close()
        }
    }

    override func close() {
        autoCloseTask?.cancel()
        autoCloseTask = nil
        hostingView = nil
        super.close()
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
    }
}

// MARK: - TranslationView

struct TranslationView: View {
    let state: TranslationWindowState
    let onClose: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showCopied = false
    @State private var displayedTranslation: String = ""
    @State private var isAnimatingText = false
    
    var body: some View {
        ZStack {
            // Background with glass morphism effect
            RoundedRectangle(cornerRadius: LTDesign.CornerRadius.xlarge)
                .fill(LTDesign.Colors.surface(for: colorScheme))
                .shadow(
                    color: colorScheme == .dark 
                        ? Color.black.opacity(0.3) 
                        : Color.black.opacity(0.1),
                    radius: 20,
                    x: 0,
                    y: 8
                )
            
            // Subtle border
            RoundedRectangle(cornerRadius: LTDesign.CornerRadius.xlarge)
                .stroke(LTDesign.Colors.subtleBorder, lineWidth: 0.5)
            
            // Gradient accent bar at top
            VStack {
                HStack {
                    AccentBar()
                        .padding(.top, LTDesign.Spacing.sm)
                    Spacer()
                }
                .padding(.horizontal, LTDesign.Spacing.lg)
                Spacer()
            }
            
            // Main content
            VStack(alignment: .leading, spacing: LTDesign.Spacing.lg) {
                // Title bar
                titleBar
                
                Divider()
                    .opacity(0.3)
                
                // Content based on state
                switch state {
                case .loading(let text):
                    loadingContent(text: text)
                    
                case .success(let original, let translation):
                    successContent(original: original, translation: translation)
                    
                case .error(let message):
                    errorContent(message: message)
                }
            }
            .padding(LTDesign.Spacing.lg)
        }
        .frame(
            width: LTDesign.WindowSize.floatingWindow.width,
            height: LTDesign.WindowSize.floatingWindow.height
        )
    }
    
    // MARK: - Title Bar
    
    private var titleBar: some View {
        HStack {
            HStack(spacing: LTDesign.Spacing.xs) {
                Image(systemName: "globe")
                    .foregroundStyle(LTDesign.Colors.primaryGradient)
                    .font(.system(size: 14, weight: .medium))
                
                Text("LuckyTrans")
                    .font(LTDesign.Typography.windowTitle)
                    .foregroundStyle(LTDesign.Colors.primaryText(for: colorScheme).opacity(0.9))
            }
            
            Spacer()
            
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(LTDesign.Colors.secondaryText(for: colorScheme))
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .hoverEffect()
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }
    
    // MARK: - Loading Content
    
    private func loadingContent(text: String) -> some View {
        VStack(alignment: .leading, spacing: LTDesign.Spacing.md) {
            // Original text preview
            Text(text)
                .font(LTDesign.Typography.originalText)
                .foregroundStyle(LTDesign.Colors.secondaryText(for: colorScheme))
                .lineLimit(3)
            
            Spacer()
            
            // Loading indicator
            HStack(spacing: LTDesign.Spacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.blue)
                
                Text("翻译中...")
                    .font(LTDesign.Typography.caption)
                    .foregroundStyle(.blue.opacity(0.9))
            }
            .padding(.horizontal, LTDesign.Spacing.md)
            .padding(.vertical, LTDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: LTDesign.CornerRadius.small)
                    .fill(Color.blue.opacity(0.08))
            )
        }
    }
    
    // MARK: - Success Content
    
    private func successContent(original: String, translation: String) -> some View {
        VStack(alignment: .leading, spacing: LTDesign.Spacing.md) {
            // Original text with quote styling
            HStack(alignment: .top, spacing: LTDesign.Spacing.xs) {
                Rectangle()
                    .fill(LTDesign.Colors.primaryGradient)
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
                
                Text(original)
                    .font(LTDesign.Typography.originalText)
                    .foregroundStyle(LTDesign.Colors.secondaryText(for: colorScheme))
                    .lineLimit(2)
                    .padding(.leading, LTDesign.Spacing.xxs)
            }
            .fixedSize(horizontal: false, vertical: true)
            
            // Translation result
            ScrollView {
                Text(displayedTranslation)
                    .font(LTDesign.Typography.translatedText)
                    .foregroundStyle(LTDesign.Colors.primaryText(for: colorScheme))
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onAppear {
                // Animate text appearance (typewriter effect for short text)
                if translation.count <= 100 {
                    animateText(translation)
                } else {
                    displayedTranslation = translation
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: LTDesign.Spacing.sm) {
                // Copy button with feedback
                Button {
                    copyToClipboard(translation)
                } label: {
                    HStack(spacing: LTDesign.Spacing.xxs) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        Text(showCopied ? "已复制" : "复制")
                    }
                    .font(LTDesign.Typography.caption)
                    .frame(minWidth: 70)
                }
                .buttonStyle(.bordered)
                .tint(showCopied ? .green : nil)
                
                // Speak button
                Button {
                    speakText(translation)
                } label: {
                    HStack(spacing: LTDesign.Spacing.xxs) {
                        Image(systemName: "speaker.wave.2")
                        Text("朗读")
                    }
                    .font(LTDesign.Typography.caption)
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Error Content
    
    private func errorContent(message: String) -> some View {
        VStack(alignment: .leading, spacing: LTDesign.Spacing.md) {
            HStack(spacing: LTDesign.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 18))
                
                Text("翻译出错")
                    .font(LTDesign.Typography.sectionTitle)
                    .foregroundStyle(LTDesign.Colors.primaryText(for: colorScheme))
            }
            
            Text(message)
                .font(LTDesign.Typography.body)
                .foregroundStyle(LTDesign.Colors.secondaryText(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Button {
                SettingsWindowManager.shared.showSettings()
                onClose()
            } label: {
                Text("检查设置")
                    .font(LTDesign.Typography.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LTDesign.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }
    
    // MARK: - Helper Methods
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + LTDesign.Animation.copyFeedbackDuration) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopied = false
            }
        }
    }
    
    private func speakText(_ text: String) {
        let synthesizer = NSSpeechSynthesizer()
        synthesizer.startSpeaking(text)
    }
    
    private func animateText(_ fullText: String) {
        displayedTranslation = ""
        isAnimatingText = true
        
        let characters = Array(fullText)
        var currentIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            if currentIndex < characters.count {
                displayedTranslation.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                isAnimatingText = false
            }
        }
    }
}
