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
                    if #available(macOS 13, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }
}

