import Foundation

/// DeepL 翻译服务
///
/// 使用 DeepL 免费翻译 API
/// 注意：需要 API Key（可在 DeepL 网站免费获取）
class DeepLTranslationService: TranslationServiceProtocol {
    // MARK: - TranslationServiceProtocol

    let serviceID = "deepl"
    let serviceName = "DeepL"
    let serviceDescription = "DeepL 专业翻译服务，需要免费 API Key"
    let requiresAPIKey = true

    let supportedLanguages = [
        "auto", "zh", "en", "ja", "ko", "fr", "de", "es", "ru", "pt",
        "it", "nl", "pl", "cs", "sv", "bg", "da", "fi", "el", "ro", "sk", "sl", "tr", "uk"
    ]

    // DeepL API 端点
    private let freeAPIEndpoint = "https://api-free.deepl.com/v2/translate"
    private let proAPIEndpoint = "https://api.deepl.com/v2/translate"

    // MARK: - Public Methods

    func isConfigured() -> Bool {
        return getAPIKey() != nil && !getAPIKey()!.isEmpty
    }

    func translate(text: String, from: String = "auto", to: String) async throws -> String {
        guard !text.isEmpty else {
            throw ServiceError.translationFailed("翻译文本为空")
        }

        guard let apiKey = getAPIKey() else {
            throw ServiceError.notConfigured(serviceName)
        }

        // 判断使用免费版还是专业版 API
        let endpoint = apiKey.hasPrefix("b63:") ? freeAPIEndpoint : proAPIEndpoint

        guard let url = URL(string: endpoint) else {
            throw ServiceError.translationFailed("无效的 API 端点")
        }

        // 构建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        // 构建请求体
        var requestBody: [String: Any] = [
            "text": [text],
            "target_lang": to.uppercased()
        ]

        // 如果指定了源语言且不是自动检测
        if !from.isEmpty && from != "auto" {
            requestBody["source_lang"] = from.uppercased()
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw ServiceError.translationFailed("请求编码失败")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.networkError(URLError(.badServerResponse))
            }

            switch httpResponse.statusCode {
            case 200:
                return try parseResponse(data)
            case 403:
                throw ServiceError.invalidAPIKey
            case 429:
                throw ServiceError.rateLimitExceeded
            case 456:
                throw ServiceError.translationFailed("请求过于频繁，请稍后再试")
            default:
                throw ServiceError.translationFailed("HTTP 状态码: \(httpResponse.statusCode)")
            }
        } catch let error as ServiceError {
            throw error
        } catch {
            throw ServiceError.networkError(error)
        }
    }

    // MARK: - Private Methods

    /// 解析 DeepL API 响应
    private func parseResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let translations = json["translations"] as? [[String: Any]],
              let firstTranslation = translations.first,
              let text = firstTranslation["text"] as? String else {
            throw ServiceError.parseError
        }

        guard !text.isEmpty else {
            throw ServiceError.translationFailed("翻译结果为空")
        }

        return text
    }

    /// 获取 DeepL API Key
    private func getAPIKey() -> String? {
        // 从 UserDefaults 获取 DeepL 专用的 API Key
        return UserDefaults.standard.string(forKey: "deepl_apiKey")
    }
}

// MARK: - DeepL API Key Management

extension DeepLTranslationService {
    /// 保存 DeepL API Key
    func saveAPIKey(_ apiKey: String) -> Bool {
        guard !apiKey.isEmpty else { return false }
        UserDefaults.standard.set(apiKey, forKey: "deepl_apiKey")
        return true
    }

    /// 检查是否有 API Key
    func hasAPIKey() -> Bool {
        guard let key = getAPIKey() else { return false }
        return !key.isEmpty
    }
}
