# 🚀 LuckyTrans 借鉴 Easydict 改进方案

> **版本**: 1.0
> **创建日期**: 2025-01-04
> **基于**: Easydict 最新版本分析

## 📋 执行摘要

### 当前 LuckyTrans 的局限性
- **取词兼容性差**: 仅使用基础 Accessibility API，很多应用无法工作
- **缺少 OCR 功能**: 无法处理图片中的文本
- **服务单一**: 仅支持 OpenAI 兼容 API
- **快捷键基础**: 缺少完整的快捷键管理系统
- **无测试覆盖**: 代码质量保障不足

### Easydict 的核心优势
- **多层级取词**: Accessibility → AppleScript → 模拟快捷键，兼容性 90%+
- **完整 OCR 引擎**: 支持诗词、论文、多列排版等复杂场景
- **多服务支持**: 10+ 翻译服务，统一架构设计
- **智能快捷键**: 完整的管理系统和自定义动作
- **完善测试**: 单元测试覆盖核心功能

### 改进优先级
1. **🔥 高优先级**: 取词技术升级、基础 OCR 功能
2. **⭐ 中优先级**: 多服务支持、快捷键系统
3. **💡 低优先级**: 智能查询、词典功能

---

## 🔧 核心改进领域

### 1. 取词技术升级

#### 当前 LuckyTrans 的问题
```swift
// LuckyTrans/TextCaptureManager.swift
// 仅使用基础 Accessibility API，兼容性差
func getSelectedTextViaAccessibility() -> String? {
    // 只能处理部分应用，很多场景失败
}
```

#### Easydict 的解决方案

**参考文件**:
- `Easydict/Swift/Utility/SystemUtility/SystemUtility+AX.swift` - 深度 Accessibility API 使用
- `Easydict/Swift/Utility/AppleScript/AppleScriptTask+Browser.swift` - 浏览器专用处理
- `Easydict/Swift/Utility/SystemUtility/SystemUtility+Selection.swift` - 智能选中文本获取

**多层级取词策略**:
```swift
// Easydict 的取词流程
Accessibility API (优先)
  ↓ 失败
AppleScript (浏览器专用)
  ↓ 失败
模拟快捷键 Cmd+C (最后手段)
```

**关键代码示例** (来自 `AppleScriptTask+Browser.swift`):
```swift
/// 浏览器专用 AppleScript 处理
enum BrowserAction {
    case getSelectedText
    case insertText(String)
    case selectAllText
}

class func getSelectedTextFromBrowser(_ bundleID: String) async throws -> String? {
    try await executeBrowserAction(.getSelectedText, bundleID: bundleID)
}

// Safari 专用脚本
private class func safariScriptFor(action: BrowserAction) -> String {
    switch action {
    case .getSelectedText:
        return """
        tell application "Safari"
            if (count of windows) > 0 then
                set selectedText to do JavaScript "window.getSelection().toString()" in front document
                return selectedText
            end if
        end tell
        """
    }
}
```

**实施步骤**:
1. 创建 `EnhancedTextCaptureManager.swift`
2. 添加浏览器检测逻辑
3. 实现 AppleScript 执行器
4. 添加回退机制

**预期效果**: 取词成功率从 60% → 90%+

---

### 2. OCR 功能完整实现

#### 当前 LuckyTrans 的问题
- **完全缺失 OCR 功能**

#### Easydict 的解决方案

**参考文件**:
- `Easydict/Swift/Service/Apple/AppleOCREngine/AppleOCREngine.swift` - 核心 OCR 引擎
- `Easydict/Swift/Service/Apple/AppleOCREngine/OCRTextNormalizer.swift` - 文本归一化
- `Easydict/Swift/Service/Apple/AppleOCREngine/OCRPoetryDetector.swift` - 诗词检测器
- `Easydict/Swift/Service/Apple/AppleOCREngine/OCRLineAnalyzer.swift` - 行分析器
- `Easydict/Swift/Utility/Extensions/String/String+OCR.swift` - OCR 文本扩展

**核心 OCR 引擎架构**:
```swift
// 来自 AppleOCREngine.swift
public class AppleOCREngine: NSObject {
    func recognizeText(
        image: NSImage,
        language: Language = .auto,
        requiresAccurateRecognition: Bool = false
    ) async throws -> EZOCRResult {

        // 1. 图像预处理
        guard image.isValid else {
            throw QueryError.error(type: .parameter, message: "Invalid image")
        }

        // 2. 执行 Vision OCR
        let observations = try await performVisionOCR(on: cgImage, language: language)

        // 3. 语言检测
        let detectedLanguage = languageDetector.detectLanguage(text: mergedText)

        // 4. 智能文本合并和处理
        textProcessor.setupOCRResult(
            ocrResult,
            observations: observations,
            ocrImage: image,
            smartMerging: smartMerging
        )

        return ocrResult
    }
}
```

**诗词检测示例** (来自 `OCRPoetryDetector.swift`):
```swift
// 诗词格式检测
class OCRPoetryDetector {
    func detectPoetryFormat(in observations: [VNRecognizedTextObservation]) -> PoetryFormat? {
        // 检测古典诗词特征：
        // - 句式对仗
        // - 韵律模式
        // - 标点符号分布

        let statistics = PoetryStatistics(
            lineCount: observations.count,
            avgCharsPerLine: avgChars,
            punctuationPattern: extractPunctuationPattern(observations)
        )

        return analyzePoetryType(statistics)
    }
}
```

**文本处理扩展** (来自 `String+OCR.swift`):
```swift
extension String {
    /// OCR 文本智能处理
    var wordComponents: [String] {
        // 中文逐字，英文连词
        // 智能分隔符处理
        // 标点符号识别
    }

    /// 检测列表格式
    var hasListPrefix: Bool {
        return trimmedText.contains(Regex.listMarkerPattern)
    }

    /// 诗词格式检测
    func detectPoetryPattern() -> Bool {
        // 韵律分析
        // 对仗检测
    }
}
```

**实施步骤**:
1. **基础 OCR** (Week 1-2)
   - 创建 `SimpleOCREngine.swift`
   - 集成 Vision 框架
   - 实现基础文本识别

2. **高级功能** (Week 3-4)
   - 添加诗词检测器
   - 实现文本归一化
   - 多列排版处理

3. **优化性能** (Week 5-6)
   - 异步处理
   - 缓存机制
   - 错误重试

**预期效果**:
- 支持图片翻译
- 准确率提升 40%+
- 处理复杂排版

---

### 3. 多服务支持架构

#### 当前 LuckyTrans 的问题
```swift
// LuckyTrans/TranslationService.swift
// 硬编码 OpenAI API，无法扩展
func translate(text: String, targetLanguage: String) async throws -> String {
    // 固定的 OpenAI API 调用
}
```

#### Easydict 的解决方案

**参考文件**:
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/ConfigurationView/BaiduTranslate+ConfigurableService.swift` - 服务配置示例
- `Easydict/Swift/Service/OpenAI/StreamService+AsyncStream.swift` - 流式翻译
- `Easydict/Swift/Service/Google/EZGoogleTranslate.m` - Google 服务
- `Easydict/Swift/Service/DeepL/EZDeepLTranslate.m` - DeepL 服务
- `Easydict/Swift/Service/Doubao/DoubaoService.swift` - 豆包服务

**统一服务协议**:
```swift
// 来自 BaiduTranslate+ConfigurableService.swift
extension EZBaiduTranslate {
    open override func configurationListItems() -> Any {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.baiduAppId, .baiduSecretKey]
        ) {
            StaticPickerCell(
                titleKey: "service.configuration.api_picker.title",
                key: .baiduServiceApiTypeKey,
                values: ServiceAPIType.allCases
            )

            SecureInputCell(
                textFieldTitleKey: "service.configuration.baidu.app_id.title",
                key: .baiduAppId
            )
        }
    }
}
```

**流式翻译处理** (来自 `StreamService+AsyncStream.swift`):
```swift
extension StreamService {
    /// 流式翻译，提升用户体验
    func streamTranslate(
        text: String,
        sourceLanguage: Language,
        targetLanguage: Language
    ) -> AsyncThrowingStream<String, Error> {

        return AsyncThrowingStream { continuation in
            // 实时返回翻译结果
            // 类似 ChatGPT 的打字效果
            Task {
                do {
                    for try await chunk in try await request.streamTranslation() {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
```

**实施步骤**:
1. **设计服务协议** (Week 1)
   ```swift
   protocol TranslationService {
       func translate(text: String, from: Language, to: Language) async throws -> String
       func streamTranslate(text: String, from: Language, to: Language) -> AsyncStream<String>
       func getConfigurationView() -> AnyView
   }
   ```

2. **重构现有服务** (Week 2)
   - 将 OpenAI 服务适配新协议
   - 添加配置界面

3. **添加新服务** (Week 3-4)
   - Google 翻译
   - DeepL 翻译
   - 豆包翻译

**预期效果**:
- 支持 5+ 翻译服务
- 用户可自由选择
- 统一的配置界面

---

### 4. 快捷键系统重构

#### 当前 LuckyTrans 的问题
```swift
// LuckyTrans/ShortcutRecorderView.swift
// 功能基础，缺少冲突检测
func recordShortcut() {
    // 简单的快捷键录制
}
```

#### Easydict 的解决方案

**参考文件**:
- `Easydict/Swift/Feature/Shortcut/Model/ShortcutManager.swift` - 快捷键管理器
- `Easydict/Swift/Feature/Shortcut/Model/ShortcutAction.swift` - 动作定义
- `Easydict/Swift/Feature/ActionManager/ActionManager.swift` - 动作管理器
- `Easydict/Swift/Feature/Shortcut/View/ShortcutModifier.swift` - 快捷键修饰器

**完整的快捷键管理系统**:
```swift
// 来自 ShortcutManager.swift
class ShortcutManager: NSObject {
    static let shared = ShortcutManager()

    func setupShortcut() {
        setupGlobalShortcutActions()

        // 首次运行设置默认快捷键
        if Defaults[.firstLaunch] {
            setDefaultShortcutKeys()
        }
    }

    func registerAction(_ action: ShortcutAction) {
        // 注册快捷键动作
        // 支持全局快捷键
        // 冲突检测
    }
}
```

**自定义动作系统** (来自 `ShortcutAction.swift`):
```swift
struct ShortcutAction {
    let actionID: String
    let title: String
    let keyCode: Int
    let modifiers: NSEvent.ModifierFlags

    func execute() {
        // 执行对应动作
        switch actionID {
        case "translate":
            // 翻译动作
        case "ocr":
            // OCR 动作
        case "mini_window":
            // 迷你窗口
        default:
            break
        }
    }
}
```

**冲突检测机制**:
```swift
// 来自 ShortcutManager+Validator.swift
extension ShortcutManager {
    func validateShortcut(_ shortcut: KeyCombo) -> ValidationResult {
        // 检查系统快捷键冲突
        if systemShortcutConflicts(shortcut) {
            return .conflict("系统快捷键")
        }

        // 检查应用内快捷键冲突
        if appShortcutConflicts(shortcut) {
            return .conflict("应用内快捷键")
        }

        return .valid
    }
}
```

**实施步骤**:
1. **重构快捷键管理** (Week 1-2)
   - 创建 `EnhancedShortcutManager.swift`
   - 实现冲突检测
   - 添加持久化

2. **自定义动作** (Week 3)
   - 动作注册系统
   - 动作编辑器
   - 动作导入导出

3. **用户界面** (Week 4)
   - 快捷键设置界面
   - 冲突提示
   - 快捷键测试

**预期效果**:
- 支持自定义动作
- 智能冲突检测
- 更好的用户体验

---

## 📅 实施时间表

### 阶段一：短期改进 (2-3 周)

#### Week 1: 取词技术升级
- [ ] 创建 `EnhancedTextCaptureManager.swift`
- [ ] 实现 AppleScript 执行器
- [ ] 添加浏览器兼容性
- [ ] 编写单元测试

#### Week 2: 基础 OCR 功能
- [ ] 创建 `SimpleOCREngine.swift`
- [ ] 集成 Vision 框架
- [ ] 实现基础文本识别
- [ ] OCR 测试用例

#### Week 3: 测试和优化
- [ ] 取词测试覆盖
- [ ] OCR 准确率优化
- [ ] 性能调优
- [ ] 文档完善

### 阶段二：中期改进 (1-2 个月)

#### Month 1: 服务架构重构
- [ ] 设计统一服务协议
- [ ] 重构 OpenAI 服务
- [ ] 添加 Google 翻译
- [ ] 添加 DeepL 翻译

#### Month 2: 快捷键系统升级
- [ ] 重构快捷键管理
- [ ] 实现自定义动作
- [ ] 冲突检测机制
- [ ] 用户界面优化

### 阶段三：长期规划 (3-6 个月)

#### 智能功能
- [ ] 智能查询模式
- [ ] 多语言自动检测
- [ ] 词典查询功能
- [ ] 历史记录管理

#### 用户体验
- [ ] 多窗口支持
- [ ] 主题定制
- [ ] 插件系统
- [ ] 云同步功能

---

## 📚 Easydict 关键文件索引

### 取词相关
```
Easydict/Swift/Utility/SystemUtility/
├── SystemUtility+AX.swift              # Accessibility API 深度使用
├── SystemUtility+AppleScript.swift     # AppleScript 工具
├── SystemUtility+Selection.swift       # 选中文本获取
└── SystemUtility.swift                # 系统工具总入口

Easydict/Swift/Utility/AppleScript/
├── AppleScriptTask+Browser.swift      # 浏览器专用 AppleScript
├── AppleScriptTask+System.swift       # 系统 AppleScript
└── AppleScriptTask.swift              # AppleScript 执行器
```

### OCR 相关
```
Easydict/Swift/Service/Apple/AppleOCREngine/
├── AppleOCREngine.swift                # 核心 OCR 引擎
├── OCRTextNormalizer.swift            # 文本归一化
├── OCRPoetryDetector.swift            # 诗词检测器
├── OCRLineAnalyzer.swift              # 行分析器
├── OCRLineMeasurer.swift              # 行测量器
├── OCRMergeAnalyzer.swift             # 合并分析器
├── OCRSectionMerger.swift             # 段落合并器
└── View/
    ├── OCRDebugView.swift             # OCR 调试界面
    ├── OCRImageView.swift             # OCR 图像显示
    └── OCRWindow.swift                # OCR 窗口

Easydict/Swift/Utility/Extensions/String/
├── String+OCR.swift                   # OCR 文本扩展
├── String+Detect.swift                # 文本检测
└── String+Extension.swift             # 通用扩展
```

### 服务相关
```
Easydict/Swift/Service/
├── OpenAI/
│   ├── OpenAIService.swift            # OpenAI 服务
│   └── StreamService+AsyncStream.swift # 流式翻译
├── Google/
│   └── EZGoogleTranslate.m            # Google 翻译
├── DeepL/
│   └── EZDeepLTranslate.m             # DeepL 翻译
├── Doubao/
│   ├── DoubaoService.swift            # 豆包服务
│   └── DoubaoTranslateType.swift      # 豆包类型定义
└── Youdao/
    ├── YoudaoService+Translate.swift  # 有道翻译
    └── YoudaoService+Dict.swift       # 有道词典

Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/ConfigurationView/
├── BaiduTranslate+ConfigurableService.swift  # 服务配置示例
├── DeepLTranslate+ConfigurableService.swift
└── DoubaoTranslate+ConfigurableService.swift
```

### 快捷键相关
```
Easydict/Swift/Feature/Shortcut/
├── Model/
│   ├── ShortcutManager.swift          # 快捷键管理器
│   ├── ShortcutAction.swift           # 动作定义
│   └── ShortcutConfictAlertMessage.swift # 冲突提示
├── View/
│   ├── KeyHolderWrapper.swift         # 快捷键录制器
│   ├── ShortcutModifier.swift         # 快捷键修饰器
│   ├── AppShortcutSettingView.swift   # 应用快捷键设置
│   └── GlobalShortcutSettingView.swift # 全局快捷键设置
└── ActionManager.swift                # 动作管理器
```

### 测试相关
```
EasydictSwiftTests/
├── OCRTests/
│   ├── OCRImageTests.swift            # OCR 图像测试
│   ├── OCRTextProcessingTests.swift   # OCR 文本处理测试
│   └── ocr-images/                    # 测试图片库
├── RegexTests/
│   ├── RegexTests.swift               # 正则表达式测试
│   └── ListRegexTests.swift           # 列表正则测试
└── SystemUtilitiesTests.swift         # 系统工具测试
```

---

## 💻 代码示例和模板

### 1. 增强型取词管理器

**文件**: `LuckyTrans/Sources/LuckyTrans/EnhancedTextCaptureManager.swift`

```swift
import Cocoa
import ApplicationServices

class EnhancedTextCaptureManager {
    static let shared = EnhancedTextCaptureManager()

    private init() {}

    func getSelectedText() -> String? {
        // 1. 优先使用增强型 Accessibility
        if let text = getSelectedTextViaEnhancedAccessibility() {
            return text
        }

        // 2. 浏览器专用 AppleScript
        if let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           isBrowser(bundleID) {
            return await getSelectedTextFromBrowser(bundleID)
        }

        // 3. 最后的回退方案
        return getSelectedTextViaClipboard()
    }

    private func getSelectedTextViaEnhancedAccessibility() -> String? {
        // 参考 Easydict 的 SystemUtility+AX.swift
        // 深度使用 Accessibility API

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElementRef: CFTypeRef?

        let error = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementRef
        )

        guard error == .success,
              let focusedElement = focusedElementRef as! AXUIElement? else {
            return nil
        }

        // 尝试获取选中文本
        return tryGetSelectedText(from: focusedElement)
    }

    private func isBrowser(_ bundleID: String) -> Bool {
        // 参考 Easydict 的 AppleScriptTask+Browser.swift
        let browsers = [
            "com.apple.Safari",
            "com.google.Chrome",
            "org.mozilla.firefox"
        ]
        return browsers.contains(bundleID)
    }

    private func getSelectedTextFromBrowser(_ bundleID: String) async -> String? {
        // 实现 AppleScript 浏览器取词
        return nil
    }
}
```

### 2. 简化的 OCR 引擎

**文件**: `LuckyTrans/Sources/LuckyTrans/SimpleOCREngine.swift`

```swift
import Vision
import CoreImage
import AppKit

class SimpleOCREngine {
    static let shared = SimpleOCREngine()

    func recognizeText(image: NSImage) async throws -> String {
        // 1. 图像验证
        guard let cgImage = image.toCGImage() else {
            throw OCRError.invalidImage
        }

        // 2. 创建 OCR 请求
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = [.chinese, .english]
        request.usesLanguageCorrection = true

        // 3. 执行识别
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        // 4. 处理结果
        guard let observations = request.results, !observations.isEmpty else {
            throw OCRError.noTextFound
        }

        // 5. 合并文本
        return mergeRecognizedText(observations)
    }

    private func mergeRecognizedText(_ observations: [VNRecognizedTextObservation]) -> String {
        // 按 y 坐标排序（从上到下）
        let sortedObservations = observations.sorted { obs1, obs2 in
            let box1 = obs1.boundingBox
            let box2 = obs2.boundingBox
            return box1.origin.y > box2.origin.y
        }

        // 提取文本
        return sortedObservations.compactMap { obs in
            obs.topCandidates(1).first?.string
        }.joined(separator: "\n")
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图像"
        case .noTextFound:
            return "未识别到文本"
        }
    }
}
```

### 3. 统一服务协议

**文件**: `LuckyTrans/Sources/LuckyTrans/TranslationServiceProtocol.swift`

```swift
import Foundation

protocol TranslationService {
    /// 服务名称
    var serviceName: String { get }

    /// 服务标识
    var serviceID: String { get }

    /// 翻译文本
    func translate(text: String, from: Language, to: Language) async throws -> String

    /// 流式翻译
    func streamTranslate(text: String, from: Language, to: Language) -> AsyncStream<String>

    /// 配置界面
    func getConfigurationView() -> AnyView

    /// 是否已配置
    func isConfigured() -> Bool
}

// 示例实现
class OpenAITranslationService: TranslationService {
    var serviceName: String { "OpenAI" }
    var serviceID: String { "openai" }

    func translate(text: String, from: Language, to: Language) async throws -> String {
        // 现有的 OpenAI 翻译逻辑
        return ""
    }

    func streamTranslate(text: String, from: Language, to: Language) -> AsyncStream<String> {
        // 实现流式翻译
        return AsyncStream { continuation in
            // 流式返回结果
        }
    }

    func getConfigurationView() -> AnyView {
        // 返回配置界面
        return AnyView(Text("OpenAI 配置"))
    }

    func isConfigured() -> Bool {
        // 检查是否已配置 API Key
        return !SettingsManager.shared.getAPIKey().isEmpty
    }
}
```

### 4. 增强型快捷键管理器

**文件**: `LuckyTrans/Sources/LuckyTrans/EnhancedShortcutManager.swift`

```swift
import Cocoa
import Carbon

class EnhancedShortcutManager {
    static let shared = EnhancedShortcutManager()

    private var registeredShortcuts: [String: KeyCombo] = [:]

    func registerShortcut(id: String, keyCombo: KeyCombo, action: @escaping () -> Void) throws {
        // 1. 验证快捷键
        let validationResult = validateShortcut(keyCombo)
        guard validationResult.isValid else {
            throw ShortcutError.conflict(validationResult.conflictMessage)
        }

        // 2. 注册快捷键
        try registerCarbonShortcut(keyCombo, action: action)

        // 3. 保存到配置
        registeredShortcuts[id] = keyCombo
    }

    private func validateShortcut(_ keyCombo: KeyCombo) -> ValidationResult {
        // 1. 检查系统快捷键冲突
        if let systemConflict = checkSystemConflict(keyCombo) {
            return .conflict("与系统快捷键冲突: \(systemConflict)")
        }

        // 2. 检查应用内快捷键冲突
        if let appConflict = checkAppConflict(keyCombo) {
            return .conflict("与应用内快捷键冲突: \(appConflict)")
        }

        return .valid
    }

    private func registerCarbonShortcut(_ keyCombo: KeyCombo, action: @escaping () -> Void) throws {
        // 使用 Carbon 框架注册全局快捷键
        var eventHotKeyRef: EventHotKeyRef?
        let keyCode = keyCombo.keyCode
        let modifiers = keyCombo.modifiers

        let eventType = EventType(specifier: EventHotKeyID(signature: OSType(), id: UInt32(keyCode)))

        let result = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            eventType,
            GetApplicationEventTarget(),
            0,
            &eventHotKeyRef
        )

        guard result == noErr else {
            throw ShortcutError.registrationFailed
        }
    }
}

struct KeyCombo {
    let keyCode: Int
    let modifiers: UInt32
}

struct ValidationResult {
    let isValid: Bool
    let conflictMessage: String?

    static let valid = ValidationResult(isValid: true, conflictMessage: nil)

    static func conflict(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, conflictMessage: message)
    }
}

enum ShortcutError: LocalizedError {
    case conflict(String)
    case registrationFailed

    var errorDescription: String? {
        switch self {
        case .conflict(let message):
            return message
        case .registrationFailed:
            return "快捷键注册失败"
        }
    }
}
```

---

## 🧪 测试用例模板

### 取词测试

**文件**: `LuckyTrans/Tests/LuckyTransTests/TextCaptureTests.swift`

```swift
import XCTest
@testable import LuckyTrans

class TextCaptureTests: XCTestCase {

    func testAccessibilityTextCapture() {
        // 测试 Accessibility 取词
        let expectation = XCTestExpectation(description: "获取选中文本")

        Task {
            if let text = await EnhancedTextCaptureManager.shared.getSelectedText() {
                XCTAssertFalse(text.isEmpty, "应该能获取到选中文本")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testBrowserTextCapture() {
        // 测试浏览器取词
        let browsers = [
            "com.apple.Safari",
            "com.google.Chrome"
        ]

        for browser in browsers {
            let isBrowser = EnhancedTextCaptureManager.shared.isBrowser(browser)
            XCTAssertTrue(isBrowser, "\(browser) 应该被识别为浏览器")
        }
    }
}
```

### OCR 测试

**文件**: `LuckyTrans/Tests/LuckyTransTests/OCRTests.swift`

```swift
import XCTest
@testable import LuckyTrans

class OCRTests: XCTestCase {

    func testBasicOCR() async throws {
        // 测试基础 OCR 功能
        let testImage = NSImage(named: "test_image")!
        let engine = SimpleOCREngine.shared

        let text = try await engine.recognizeText(image: testImage)
        XCTAssertFalse(text.isEmpty, "应该能识别出文本")
    }

    func testChineseOCR() async throws {
        // 测试中文 OCR
        let chineseImage = NSImage(named: "chinese_text")!
        let text = try await SimpleOCREngine.shared.recognizeText(image: chineseImage)

        // 验证是否包含中文字符
        let hasChinese = text.contains { $0.isChineseCharacter }
        XCTAssertTrue(hasChinese, "应该能识别中文字符")
    }

    func testEnglishOCR() async throws {
        // 测试英文 OCR
        let englishImage = NSImage(named: "english_text")!
        let text = try await SimpleOCREngine.shared.recognizeText(image: englishImage)

        // 验证是否包含英文单词
        let hasEnglish = text.contains { $0.isLetter }
        XCTAssertTrue(hasEnglish, "应该能识别英文字符")
    }
}
```

---

## ⚠️ 风险评估和注意事项

### 兼容性风险

#### macOS 版本兼容
- **风险**: 新 API 可能不支持旧版本 macOS
- **缓解**:
  ```swift
  @available(macOS 13.0, *)
  class EnhancedTextCaptureManager {
      // 使用新 API 的代码
  }

  // 提供降级方案
  class LegacyTextCaptureManager {
      // 兼容旧版本的实现
  }
  ```

#### 应用权限
- **风险**: 辅助功能权限、屏幕录制权限
- **缓解**:
  ```swift
  func checkPermissions() -> Bool {
      // 检查辅助功能权限
      let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
      let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

      if !isTrusted {
          // 引导用户开启权限
          showPermissionGuide()
      }

      return isTrusted
  }
  ```

### 性能风险

#### OCR 性能
- **风险**: 大图片处理慢，影响用户体验
- **缓解**:
  ```swift
  func recognizeTextWithOptimization(image: NSImage) async throws -> String {
      // 1. 图片预处理
      let resizedImage = resizeImageIfNeeded(image, maxSize: CGSize(width: 2000, height: 2000))

      // 2. 异步处理
      return await Task.detached(priority: .userInitiated) {
          try await SimpleOCREngine.shared.recognizeText(image: resizedImage)
      }.value
  }
  ```

#### 内存占用
- **风险**: 多服务同时运行时内存占用高
- **缓解**:
  ```swift
  class ServiceManager {
      private var activeServices: [String: TranslationService] = [:]

      func getService(_ serviceID: String) -> TranslationService {
          // 懒加载服务
          if let service = activeServices[serviceID] {
              return service
          }

          let service = createService(serviceID)
          activeServices[serviceID] = service
          return service
      }

      func releaseUnusedServices() {
          // 释放不活跃的服务
      }
  }
  ```

### 用户体验风险

#### 复杂度增加
- **风险**: 功能增加导致界面复杂
- **缓解**:
  ```swift
  struct SettingsView: View {
      @State private var selectedTab: SettingsTab = .general

      var body: some View {
          TabView(selection: $selectedTab) {
              GeneralSettings()
                  .tabItem { Label("通用", systemImage: "gearshape") }

              TranslationSettings()
                  .tabItem { Label("翻译", systemImage: "text.bubble") }

              ShortcutSettings()
                  .tabItem { Label("快捷键", systemImage: "command") }
          }
      }
  }
  ```

#### 学习成本
- **风险**: 用户需要学习新功能
- **缓解**:
  - 提供详细的帮助文档
  - 首次运行时显示引导
  - 提供默认配置

---

## ✅ 实施检查清单

### 阶段一检查清单

#### Week 1: 取词技术升级
- [ ] 创建 `EnhancedTextCaptureManager.swift`
- [ ] 实现 AppleScript 执行器
- [ ] 添加 Safari 支持
- [ ] 添加 Chrome 支持
- [ ] 添加 Firefox 支持
- [ ] 实现回退机制
- [ ] 编写单元测试
- [ ] 测试覆盖率 > 80%
- [ ] 性能测试
- [ ] 更新文档

#### Week 2: 基础 OCR 功能
- [ ] 创建 `SimpleOCREngine.swift`
- [ ] 集成 Vision 框架
- [ ] 实现基础文本识别
- [ ] 添加中文支持
- [ ] 添加英文支持
- [ ] 实现文本合并逻辑
- [ ] 创建 OCR 测试用例
- [ ] 准备测试图片
- [ ] 性能优化
- [ ] 错误处理完善

#### Week 3: 测试和优化
- [ ] 完整的取词测试
- [ ] 完整的 OCR 测试
- [ ] 准确率基准测试
- [ ] 性能基准测试
- [ ] 用户测试
- [ ] Bug 修复
- [ ] 文档完善
- [ ] 发布准备

### 阶段二检查清单

#### Month 1: 服务架构重构
- [ ] 设计服务协议
- [ ] 创建协议文档
- [ ] 重构 OpenAI 服务
- [ ] 实现 Google 翻译
- [ ] 实现 DeepL 翻译
- [ ] 添加豆包翻译
- [ ] 统一配置界面
- [ ] 服务切换功能
- [ ] 服务测试
- [ ] 性能优化

#### Month 2: 快捷键系统升级
- [ ] 重构快捷键管理
- [ ] 实现冲突检测
- [ ] 创建动作系统
- [ ] 动作编辑器
- [ ] 快捷键录制器
- [ ] 配置界面
- [ ] 导入导出功能
- [ ] 测试覆盖
- [ ] 用户测试
- [ ] 文档完善

### 阶段三检查清单

#### 智能功能
- [ ] 智能查询模式设计
- [ ] 多语言检测
- [ ] 词典功能设计
- [ ] 历史记录管理
- [ ] 用户偏好学习
- [ ] 性能优化

#### 用户体验
- [ ] 多窗口支持
- [ ] 主题定制
- [ ] 插件系统设计
- [ ] 云同步功能
- [ ] 用户测试
- [ ] 反馈收集

---

## 📊 成功指标

### 技术指标
- **取词成功率**: 60% → 90%+
- **OCR 准确率**: 基础识别 > 85%
- **测试覆盖率**: 0% → 80%+
- **性能**: 响应时间 < 1s

### 用户体验指标
- **功能完整度**: 基础 → 专业级
- **服务支持数**: 1 → 5+
- **自定义能力**: 有限 → 完全自定义
- **文档完整度**: 简单 → 详细全面

### 开发质量指标
- **代码组织**: 扁平 → 模块化
- **可维护性**: 中等 → 高
- **可扩展性**: 低 → 高
- **错误处理**: 基础 → 完善

---

## 🎯 总结

这个改进方案为 LuckyTrans 提供了从轻量级翻译工具到专业翻译应用的完整升级路径。通过借鉴 Easydict 的成熟技术，LuckyTrans 将在以下方面得到显著提升：

### 核心优势
1. **取词技术**: 多层级策略，兼容性大幅提升
2. **OCR 功能**: 从无到有，支持复杂场景
3. **服务架构**: 统一协议，易于扩展
4. **快捷键系统**: 完整管理，自定义灵活

### 实施建议
1. **循序渐进**: 按阶段实施，确保每个阶段都有可交付成果
2. **测试先行**: 新功能必须有测试覆盖
3. **用户反馈**: 及时收集用户反馈，调整开发方向
4. **文档同步**: 代码和文档同步更新

### 长期价值
通过这个方案的实施，LuckyTrans 将：
- 成为功能完整的翻译工具
- 具备良好的扩展性和维护性
- 提供优秀的用户体验
- 建立完善的测试体系

**预期时间**: 3-6 个月完成全部改进
**预期投入**: 中等规模开发资源
**预期收益**: 产品竞争力大幅提升

---

## 📞 支持和反馈

如在实施过程中遇到问题，建议：
1. 参考 Easydict 源码的具体实现
2. 查阅本文档中的代码示例
3. 查阅相关技术文档
4. 进行充分测试验证

**持续改进**: 根据实际使用情况，持续优化和改进各项功能。

---

*本方案基于 Easydict 最新版本分析，具体实施时请根据实际情况调整。*