import XCTest
@testable import LuckyTrans

/// LuckyTrans 基础测试
final class LuckyTransTests: XCTestCase {

    // MARK: - TranslationServiceProtocol Tests

    func testServiceTypeIdentifiers() {
        // 测试服务类型标识符
        XCTAssertEqual(TranslationServiceType.openAI.rawValue, "openai")
        XCTAssertEqual(TranslationServiceType.google.rawValue, "google")
        XCTAssertEqual(TranslationServiceType.deepL.rawValue, "deepl")
        XCTAssertEqual(TranslationServiceType.baidu.rawValue, "baidu")
        XCTAssertEqual(TranslationServiceType.youdao.rawValue, "youdao")
    }

    func testServiceTypeDisplayNames() {
        // 测试服务显示名称
        XCTAssertEqual(TranslationServiceType.openAI.displayName, "OpenAI")
        XCTAssertEqual(TranslationServiceType.google.displayName, "Google 翻译")
        XCTAssertEqual(TranslationServiceType.deepL.displayName, "DeepL")
        XCTAssertEqual(TranslationServiceType.baidu.displayName, "百度翻译")
        XCTAssertEqual(TranslationServiceType.youdao.displayName, "有道翻译")
    }

    func testAllServicesHaveUniqueIds() {
        // 测试所有服务 ID 都是唯一的
        let ids = TranslationServiceType.allCases.map { $0.rawValue }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "服务 ID 应该是唯一的")
    }

    // MARK: - OCRResult Tests

    func testOCRResultInitialization() {
        // 测试 OCR 结果初始化
        let result = OCRResult()

        XCTAssertTrue(result.isEmpty, "新创建的 OCRResult 应该是空的")
        XCTAssertEqual(result.lineCount, 0, "新创建的 OCRResult 应该有 0 行")
        XCTAssertEqual(result.confidence, 0.0, "新创建的 OCRResult 置信度应该是 0")
    }

    func testOCRResultWithData() {
        // 测试带有数据的 OCR 结果
        let result = OCRResult(
            texts: ["Hello", "World"],
            mergedText: "Hello\nWorld",
            confidence: 0.95
        )

        XCTAssertFalse(result.isEmpty, "有数据的 OCRResult 不应该是空的")
        XCTAssertEqual(result.lineCount, 2, "应该有 2 行文本")
        XCTAssertEqual(result.mergedText, "Hello\nWorld", "合并文本应该正确")
        XCTAssertEqual(result.confidence, 0.95, accuracy: 0.001, "置信度应该是 0.95")
    }

    // MARK: - ServiceError Tests

    func testServiceErrorDescriptions() {
        // 测试错误描述
        let notConfigured = ServiceError.notConfigured("OpenAI")
        XCTAssertNotNil(notConfigured.errorDescription)
        XCTAssertTrue(notConfigured.errorDescription!.contains("OpenAI"))

        let invalidKey = ServiceError.invalidAPIKey
        XCTAssertEqual(invalidKey.errorDescription, "API Key 无效")

        let rateLimit = ServiceError.rateLimitExceeded
        XCTAssertEqual(rateLimit.errorDescription, "请求过于频繁，请稍后再试")
    }

    // MARK: - SupportedBrowser Tests

    func testBrowserProperties() {
        // 测试浏览器属性
        XCTAssertEqual(SupportedBrowser.safari.displayName, "Safari")
        XCTAssertEqual(SupportedBrowser.chrome.displayName, "Chrome")
        XCTAssertEqual(SupportedBrowser.edge.displayName, "Edge")

        XCTAssertTrue(SupportedBrowser.safari.isSafari)
        XCTAssertFalse(SupportedBrowser.chrome.isSafari)

        XCTAssertTrue(SupportedBrowser.chrome.isChromeKernel)
        XCTAssertTrue(SupportedBrowser.brave.isChromeKernel)
        XCTAssertFalse(SupportedBrowser.safari.isChromeKernel)
    }

    // MARK: - Integration Tests

    func testServiceManagerInitialization() async throws {
        // 测试服务管理器初始化
        let manager = TranslationServiceManager.shared

        // 检查默认服务是 OpenAI
        XCTAssertEqual(manager.currentServiceType, .openAI)

        // 检查可以获取服务
        let openAIService = manager.getService(for: .openAI)
        XCTAssertEqual(openAIService.serviceID, "openai")

        let googleService = manager.getService(for: .google)
        XCTAssertEqual(googleService.serviceID, "google")
    }

    func testServiceAvailability() async throws {
        // 测试服务可用性
        let manager = TranslationServiceManager.shared

        // Google 不需要配置，应该总是可用的
        XCTAssertTrue(manager.isServiceAvailable(.google))

        // OpenAI 需要 API Key
        let openAIAvailable = manager.isServiceAvailable(.openAI)
        let openAIService = manager.getService(for: .openAI)
        XCTAssertEqual(openAIAvailable, openAIService.isConfigured())
    }

    func testGoogleServiceRequiresNoKey() {
        // 测试 Google 翻译不需要 API Key
        let googleService = GoogleTranslationService()
        XCTAssertFalse(googleService.requiresAPIKey, "Google 翻译不应该需要 API Key")
        XCTAssertTrue(googleService.isConfigured(), "Google 翻译应该总是配置好的")
    }

    func testDeepLServiceRequiresKey() {
        // 测试 DeepL 需要 API Key
        let deepLService = DeepLTranslationService()
        XCTAssertTrue(deepLService.requiresAPIKey, "DeepL 应该需要 API Key")
        XCTAssertFalse(deepLService.isConfigured(), "没有 API Key 时不应该被配置")
    }

    // MARK: - Performance Tests

    func testServiceManagerPerformance() {
        // 测试服务管理器性能
        measure {
            for _ in 0..<100 {
                _ = TranslationServiceManager.shared.getService(for: .google)
            }
        }
    }
}
