import SwiftUI

@main
struct LuckyTransApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var menuBarManager = MenuBarManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(settingsManager)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 500, height: 400)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    SettingsWindowManager.shared.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

