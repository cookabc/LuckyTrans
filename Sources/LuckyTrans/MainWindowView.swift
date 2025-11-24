import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 应用图标和标题
            VStack(spacing: 12) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("LuckyTrans")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("快速翻译工具")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // 状态信息
            VStack(spacing: 16) {
                // API Key 状态
                HStack {
                    Image(systemName: settingsManager.hasAPIKey() ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(settingsManager.hasAPIKey() ? .green : .orange)
                    Text(settingsManager.hasAPIKey() ? "API Key 已配置" : "API Key 未配置")
                        .font(.body)
                }
                
                // 目标语言
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                    Text("目标语言: \(settingsManager.targetLanguage)")
                        .font(.body)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
            
            // 操作按钮
            VStack(spacing: 12) {
                Button(action: {
                    showSettings = true
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }) {
                    Label("打开设置", systemImage: "gearshape.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button(action: {
                    if let window = NSApplication.shared.windows.first {
                        window.orderOut(nil)
                    }
                }) {
                    Label("隐藏到菜单栏", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(width: 500, height: 400)
        .onAppear {
            // 首次启动时，如果没有配置 API Key，自动打开设置窗口
            if !settingsManager.hasAPIKey() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
            }
        }
    }
}

