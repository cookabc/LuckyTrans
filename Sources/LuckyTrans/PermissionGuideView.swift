import SwiftUI
import AppKit

// MARK: - Permission Guide View

/// Dedicated view for first-time users or when permissions are missing
struct PermissionGuideView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasPermission = false
    @State private var isCheckingPermission = false
    
    var body: some View {
        VStack(spacing: LTDesign.Spacing.xxxl) {
            // Lock Icon
            ZStack {
                Circle()
                    .fill(colorScheme == .dark 
                        ? Color.white.opacity(0.05) 
                        : Color.black.opacity(0.03))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }
            
            // Title & Description
            VStack(spacing: LTDesign.Spacing.sm) {
                Text("需要权限")
                    .font(.title2.bold())
                
                Text("LuckyTrans 需要辅助功能权限才能获取你选中的文本")
                    .font(LTDesign.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Instruction Steps
            VStack(alignment: .leading, spacing: LTDesign.Spacing.sm) {
                InstructionRow(number: 1, text: "打开系统设置")
                InstructionRow(number: 2, text: "进入 隐私与安全性 > 辅助功能")
                InstructionRow(number: 3, text: "勾选 LuckyTrans")
            }
            .padding(LTDesign.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: LTDesign.CornerRadius.large)
                    .fill(colorScheme == .dark 
                        ? Color.white.opacity(0.05) 
                        : Color.black.opacity(0.03))
            )
            
            // Action Button
            Button {
                openAccessibilitySettings()
            } label: {
                HStack(spacing: LTDesign.Spacing.sm) {
                    Image(systemName: "gear")
                    Text("打开系统设置")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, LTDesign.Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Permission Status
            if isCheckingPermission {
                HStack(spacing: LTDesign.Spacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在检查权限...")
                        .font(LTDesign.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            } else if hasPermission {
                HStack(spacing: LTDesign.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("权限已授予")
                        .font(LTDesign.Typography.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(LTDesign.Spacing.xxxl)
        .frame(width: LTDesign.WindowSize.permissionGuide.width)
        .onAppear {
            checkPermission()
        }
    }
    
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        
        // Start polling for permission changes
        startPermissionPolling()
    }
    
    private func checkPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    private func startPermissionPolling() {
        isCheckingPermission = true
        
        // Poll every second for permission changes
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
            let granted = AXIsProcessTrustedWithOptions(options as CFDictionary)
            
            if granted {
                timer.invalidate()
                withAnimation {
                    hasPermission = true
                    isCheckingPermission = false
                }
                
                // Notify that permission was granted
                NotificationCenter.default.post(
                    name: NSNotification.Name("AccessibilityPermissionGranted"),
                    object: nil
                )
            }
        }
        
        // Stop polling after 60 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            isCheckingPermission = false
        }
    }
}

// MARK: - Permission Guide Window Controller

class PermissionGuideWindowController {
    static let shared = PermissionGuideWindowController()
    
    private var window: NSWindow?
    
    private init() {}
    
    func showIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !hasPermission {
            showWindow()
        }
    }
    
    func showWindow() {
        if window == nil {
            let contentView = PermissionGuideView()
            
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            
            window?.title = "LuckyTrans - 权限设置"
            window?.center()
            window?.contentView = NSHostingView(rootView: contentView)
            window?.isReleasedWhenClosed = false
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeWindow() {
        window?.close()
    }
}

// MARK: - Preview

#Preview {
    PermissionGuideView()
}
