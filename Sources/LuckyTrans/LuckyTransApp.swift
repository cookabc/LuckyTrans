import SwiftUI

@main
struct LuckyTransApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var menuBarManager = MenuBarManager.shared
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

