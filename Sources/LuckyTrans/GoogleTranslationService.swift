import Foundation

/// Google 翻译服务
///
/// 使用 Google Translate 免费网页 API
/// 注意：这是非官方 API，可能随时失效
class GoogleTranslationService: TranslationServiceProtocol {
    // MARK: - TranslationServiceProtocol

    let serviceID = "google"
    let serviceName = "Google 翻译"
    let serviceDescription = "Google 免费翻译服务，无需 API Key"
    let requiresAPIKey = false

    let supportedLanguages = [
        "auto", "zh", "en", "ja", "ko", "fr", "de", "es", "ru", "pt",
        "it", "vi", "th", "ar", "hi", "id", "ms", "nl", "pl", "tr"
    ]

    // MARK: - Public Methods

    func isConfigured() -> Bool {
        // Google 翻译不需要配置
        return true
    }

    func translate(text: String, from: String = "auto", to: String) async throws -> String {
        guard !text.isEmpty else {
            throw ServiceError.translationFailed("翻译文本为空")
        }

        // 构建 URL
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: from.isEmpty ? "auto" : from),
            URLQueryItem(name: "tl", value: to),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: text)
        ]

        guard let url = components?.url else {
            throw ServiceError.translationFailed("无效的请求 URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.networkError(URLError(.badServerResponse))
            }

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 429 {
                    throw ServiceError.rateLimitExceeded
                }
                throw ServiceError.translationFailed("HTTP 状态码: \(httpResponse.statusCode)")
            }

            return try parseResponse(data)
        } catch let error as ServiceError {
            throw error
        } catch {
            throw ServiceError.networkError(error)
        }
    }

    // MARK: - Private Methods

    /// 解析 Google Translate API 响应
    /// 响应格式: [[[["译文", "原文", ...]], ...], "源语言", ...]
    private func parseResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw ServiceError.parseError
        }

        guard let array = json as? [Any],
              let translations = array.first as? [Any] else {
            throw ServiceError.parseError
        }

        var result = ""

        // 提取所有翻译片段
        for item in translations {
            if let translationArray = item as? [Any],
               let translatedText = translationArray.first as? String {
                result += translatedText
            }
        }

        guard !result.isEmpty else {
            throw ServiceError.translationFailed("翻译结果为空")
        }

        return result
    }
}

// MARK: - Language Code Mapping

extension GoogleTranslationService {
    /// 语言代码映射
    static let languageNames: [String: String] = [
        "auto": "自动检测",
        "zh": "中文",
        "zh-CN": "简体中文",
        "zh-TW": "繁体中文",
        "en": "英语",
        "ja": "日语",
        "ko": "韩语",
        "fr": "法语",
        "de": "德语",
        "es": "西班牙语",
        "ru": "俄语",
        "pt": "葡萄牙语",
        "it": "意大利语",
        "vi": "越南语",
        "th": "泰语",
        "ar": "阿拉伯语",
        "hi": "印地语",
        "id": "印尼语",
        "ms": "马来语",
        "nl": "荷兰语",
        "pl": "波兰语",
        "tr": "土耳其语"
    ]
}
