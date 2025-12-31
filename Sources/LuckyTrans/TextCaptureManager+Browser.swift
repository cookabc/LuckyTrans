import Foundation
import AppKit

// MARK: - AppleScript Support for Browser Text Capture

/// 支持的浏览器列表
enum SupportedBrowser: String, CaseIterable {
    case safari = "com.apple.Safari"
    case chrome = "com.google.Chrome"
    case edge = "com.microsoft.edgemac"
    case arc = "company.thebrowser.Browser"
    case brave = "com.brave.Browser"

    var displayName: String {
        switch self {
        case .safari: return "Safari"
        case .chrome: return "Chrome"
        case .edge: return "Edge"
        case .arc: return "Arc"
        case .brave: return "Brave"
        }
    }

    /// 是否为 Safari (使用不同的 AppleScript 语法)
    var isSafari: Bool { self == .safari }

    /// 是否为 Chrome 内核浏览器
    var isChromeKernel: Bool {
        switch self {
        case .chrome, .edge, .arc, .brave: return true
        case .safari: return false
        }
    }
}

// MARK: - TextCaptureManager Browser Extension

extension TextCaptureManager {
    /// 从浏览器获取选中文本（使用 AppleScript）
    func getSelectedTextFromBrowser(_ bundleID: String) -> String? {
        guard let browser = SupportedBrowser(rawValue: bundleID) else {
            return nil
        }

        return runBrowserScript(browser: browser)
    }

    /// 检查当前应用是否为支持的浏览器
    func isBrowser(_ bundleID: String) -> Bool {
        SupportedBrowser(rawValue: bundleID) != nil
    }

    // MARK: - Private Methods

    /// 执行浏览器 AppleScript
    private func runBrowserScript(browser: SupportedBrowser) -> String? {
        let script = getSelectedTextScript(for: browser)

        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)

        guard let output = appleScript?.executeAndReturnError(&error) else {
            if let error = error {
                print("Browser AppleScript error: \(error)")
            }
            return nil
        }

        let result = output.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        return result?.isEmpty == false ? result : nil
    }

    /// 获取选中文本的 AppleScript
    private func getSelectedTextScript(for browser: SupportedBrowser) -> String {
        if browser.isSafari {
            return """
            tell application id "\(browser.rawValue)"
                tell front window
                    set selection_text to do JavaScript "window.getSelection().toString();" in current tab
                end tell
            end tell
            """
        } else if browser.isChromeKernel {
            return """
            tell application id "\(browser.rawValue)"
                tell active tab of front window
                    set selection_text to execute javascript "window.getSelection().toString();"
                end tell
            end tell
            """
        }

        return ""
    }
}

// MARK: - AppleScript Utilities

extension TextCaptureManager {
    /// 通用 AppleScript 执行器
    func runAppleScript(_ source: String, timeout: TimeInterval = 1.0) -> String? {
        let script = NSAppleScript(source: source)

        var errorDict: NSDictionary?
        let result = script?.executeAndReturnError(&errorDict)

        if let error = errorDict {
            print("AppleScript error: \(error)")
            return nil
        }

        return result?.stringValue
    }

    /// 异步执行 AppleScript
    func runAppleScriptAsync(_ source: String, timeout: TimeInterval = 1.0) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.runAppleScript(source, timeout: timeout)
                continuation.resume(returning: result)
            }
        }
    }

    /// JavaScript 字符串转义（用于嵌入 AppleScript）
    private func escapeJavaScriptString(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }
}

// MARK: - Browser Detection Utilities

extension TextCaptureManager {
    /// 获取当前浏览器类型
    func getCurrentBrowser() -> SupportedBrowser? {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return nil
        }
        return SupportedBrowser(rawValue: bundleID)
    }

    /// 检查当前应用是否为支持的浏览器
    var isCurrentAppBrowser: Bool {
        getCurrentBrowser() != nil
    }

    /// 获取当前浏览器的 Bundle ID
    var currentBrowserBundleID: String? {
        guard isCurrentAppBrowser else { return nil }
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
}
