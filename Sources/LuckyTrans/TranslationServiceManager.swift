import Foundation

/// 翻译服务管理器
///
/// 负责管理所有翻译服务，提供统一的翻译接口
@MainActor
class TranslationServiceManager: ObservableObject {
    static let shared = TranslationServiceManager()

    // MARK: - Published Properties

    /// 当前选中的服务类型
    @Published var currentServiceType: TranslationServiceType {
        didSet {
            saveCurrentServiceType()
        }
    }

    /// 可用的服务列表
    @Published var availableServices: [TranslationServiceType] = []

    // MARK: - Private Properties

    private var services: [TranslationServiceType: TranslationServiceProtocol] = [:]

    // MARK: - Initialization

    private init() {
        // 加载保存的服务类型
        let savedType = UserDefaults.standard.string(forKey: "currentServiceType") ?? TranslationServiceType.openAI.rawValue
        self.currentServiceType = TranslationServiceType(rawValue: savedType) ?? .openAI

        // 注册服务
        registerServices()

        // 加载可用服务
        updateAvailableServices()
    }

    // MARK: - Public Methods

    /// 获取当前服务
    func getCurrentService() -> TranslationServiceProtocol {
        return getService(for: currentServiceType)
    }

    /// 获取指定类型的服务
    func getService(for type: TranslationServiceType) -> TranslationServiceProtocol {
        // 如果服务已缓存，返回缓存的服务
        if let service = services[type] {
            return service
        }

        // 否则创建新服务
        let service = createService(for: type)
        services[type] = service
        return service
    }

    /// 使用当前服务翻译
    func translate(text: String, from: String = "auto", to: String) async throws -> String {
        let service = getCurrentService()

        // 检查服务是否已配置
        guard service.isConfigured() else {
            throw ServiceError.notConfigured(service.serviceName)
        }

        return try await service.translate(text: text, from: from, to: to)
    }

    /// 切换服务
    func switchService(to type: TranslationServiceType) {
        currentServiceType = type
    }

    /// 检查服务是否可用
    func isServiceAvailable(_ type: TranslationServiceType) -> Bool {
        let service = getService(for: type)
        return service.isConfigured()
    }

    /// 获取服务状态描述
    func getServiceStatus(_ type: TranslationServiceType) -> String {
        let service = getService(for: type)
        if service.isConfigured() {
            return "已配置"
        } else {
            return "未配置"
        }
    }

    // MARK: - Private Methods

    /// 注册所有服务
    private func registerServices() {
        // OpenAI 服务（使用现有 TranslationService 的适配）
        services[.openAI] = OpenAIServiceAdapter()

        // Google 服务
        services[.google] = GoogleTranslationService()

        // DeepL 服务
        services[.deepL] = DeepLTranslationService()

        // 百度服务
        services[.baidu] = BaiduTranslationService()

        // 其他服务可以在这里添加
        // services[.youdao] = YoudaoTranslationService()
    }

    /// 创建服务实例
    private func createService(for type: TranslationServiceType) -> TranslationServiceProtocol {
        switch type {
        case .openAI:
            return OpenAIServiceAdapter()
        case .google:
            return GoogleTranslationService()
        case .deepL:
            return DeepLTranslationService()
        case .baidu:
            return BaiduTranslationService()
        case .youdao:
            // 暂未实现
            return UnimplementedService(type: type)
        }
    }

    /// 更新可用服务列表
    private func updateAvailableServices() {
        availableServices = TranslationServiceType.allCases
    }

    /// 保存当前服务类型
    private func saveCurrentServiceType() {
        UserDefaults.standard.set(currentServiceType.rawValue, forKey: "currentServiceType")
    }
}

// MARK: - OpenAI Service Adapter

/// OpenAI 服务适配器
/// 将现有的 TranslationService 适配到 TranslationServiceProtocol
class OpenAIServiceAdapter: TranslationServiceProtocol {
    let serviceID = "openai"
    let serviceName = "OpenAI"
    let serviceDescription = "使用 OpenAI API 进行高质量翻译"
    let requiresAPIKey = true

    let supportedLanguages = [
        "auto", "zh", "en", "ja", "ko", "fr", "de", "es", "ru", "pt"
    ]

    func isConfigured() -> Bool {
        return SettingsManager.shared.hasAPIKey()
    }

    func translate(text: String, from: String = "auto", to: String) async throws -> String {
        // 使用现有的 TranslationService
        return try await TranslationService.shared.translate(text: text, targetLanguage: to)
    }
}

// MARK: - Unimplemented Service

/// 未实现的服务占位符
class UnimplementedService: TranslationServiceProtocol {
    let serviceID: String
    let serviceName: String
    let serviceDescription: String
    let requiresAPIKey: Bool = false
    let supportedLanguages: [String] = []

    init(type: TranslationServiceType) {
        self.serviceID = type.rawValue
        self.serviceName = type.displayName
        self.serviceDescription = "该服务暂未实现"
    }

    func isConfigured() -> Bool {
        return false
    }

    func translate(text: String, from: String, to: String) async throws -> String {
        throw ServiceError.translationFailed("该服务暂未实现")
    }
}
