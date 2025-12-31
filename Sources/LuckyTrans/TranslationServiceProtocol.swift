import Foundation

// MARK: - Translation Service Protocol

/// 统一的翻译服务协议
protocol TranslationServiceProtocol {
    /// 服务唯一标识符
    var serviceID: String { get }

    /// 服务显示名称
    var serviceName: String { get }

    /// 服务描述
    var serviceDescription: String { get }

    /// 是否需要 API Key
    var requiresAPIKey: Bool { get }

    /// 支持的语言列表
    var supportedLanguages: [String] { get }

    /// 检查服务是否已配置
    func isConfigured() -> Bool

    /// 翻译文本
    /// - Parameters:
    ///   - text: 要翻译的文本
    ///   - from: 源语言（空字符串表示自动检测）
    ///   - to: 目标语言
    /// - Returns: 翻译结果
    func translate(text: String, from: String, to: String) async throws -> String

    /// 可选：流式翻译（默认不支持）
    func streamTranslate(text: String, from: String, to: String) -> AsyncThrowingStream<String, Error>?
}

/// 默认实现
extension TranslationServiceProtocol {
    func streamTranslate(text: String, from: String, to: String) -> AsyncThrowingStream<String, Error>? {
        return nil
    }
}

// MARK: - Translation Service Type

/// 翻译服务类型枚举
enum TranslationServiceType: String, CaseIterable, Identifiable {
    case openAI = "openai"
    case google = "google"
    case deepL = "deepl"
    case baidu = "baidu"
    case youdao = "youdao"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .google: return "Google 翻译"
        case .deepL: return "DeepL"
        case .baidu: return "百度翻译"
        case .youdao: return "有道翻译"
        }
    }

    var description: String {
        switch self {
        case .openAI: return "使用 OpenAI API 进行高质量翻译"
        case .google: return "Google 免费翻译服务"
        case .deepL: return "DeepL 专业翻译服务"
        case .baidu: return "百度翻译服务"
        case .youdao: return "有道翻译服务"
        }
    }
}

// MARK: - Translation Result

/// 翻译结果模型
struct TranslationResult {
    /// 原文
    let originalText: String

    /// 译文
    let translatedText: String

    /// 源语言
    let sourceLanguage: String

    /// 目标语言
    let targetLanguage: String

    /// 使用的服务
    let serviceType: TranslationServiceType

    /// 是否检测到源语言（自动检测）
    let isDetectedLanguage: Bool
}

// MARK: - Translation Error

/// 翻译服务错误
enum ServiceError: LocalizedError {
    case notConfigured(String)
    case invalidAPIKey
    case networkError(Error)
    case rateLimitExceeded
    case unsupportedLanguage(String)
    case translationFailed(String)
    case parseError
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured(let service):
            return "\(service) 未配置，请先设置 API Key"
        case .invalidAPIKey:
            return "API Key 无效"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "请求过于频繁，请稍后再试"
        case .unsupportedLanguage(let lang):
            return "不支持的语言: \(lang)"
        case .translationFailed(let message):
            return "翻译失败: \(message)"
        case .parseError:
            return "解析响应失败"
        case .unknownError(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}
