import Foundation
import CryptoKit
import CommonCrypto

/// 百度翻译服务
///
/// 使用百度翻译 API
/// 需要申请 App ID 和 Secret Key
class BaiduTranslationService: TranslationServiceProtocol {
    // MARK: - TranslationServiceProtocol

    let serviceID = "baidu"
    let serviceName = "百度翻译"
    let serviceDescription = "百度翻译服务，需要 App ID 和密钥"
    let requiresAPIKey = true

    let supportedLanguages = [
        "auto", "zh", "en", "ja", "ko", "fr", "de", "es", "ru", "pt",
        "it", "th", "ar", "vi", "ms", "id"
    ]

    // API 端点
    private let apiEndpoint = "https://fanyi-api.baidu.com/api/trans/vip/translate"

    // MARK: - Public Methods

    func isConfigured() -> Bool {
        guard let appID = getAppID(), !appID.isEmpty else { return false }
        guard let key = getSecretKey(), !key.isEmpty else { return false }
        return true
    }

    func translate(text: String, from: String = "auto", to: String) async throws -> String {
        guard !text.isEmpty else {
            throw ServiceError.translationFailed("翻译文本为空")
        }

        guard let appID = getAppID(), !appID.isEmpty else {
            throw ServiceError.notConfigured(serviceName)
        }

        guard let secretKey = getSecretKey(), !secretKey.isEmpty else {
            throw ServiceError.notConfigured(serviceName)
        }

        // 生成签名
        let salt = String(Int(Date().timeIntervalSince1970 * 1000))
        let sign = generateSign(text: text, appID: appID, salt: salt, key: secretKey)

        // 构建 URL
        var components = URLComponents(string: apiEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "from", value: from.isEmpty ? "auto" : from),
            URLQueryItem(name: "to", value: to),
            URLQueryItem(name: "appid", value: appID),
            URLQueryItem(name: "salt", value: salt),
            URLQueryItem(name: "sign", value: sign)
        ]

        guard let url = components?.url else {
            throw ServiceError.translationFailed("无效的请求 URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.networkError(URLError(.badServerResponse))
            }

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 52003 {
                    throw ServiceError.invalidAPIKey
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

    /// 生成百度 API 签名
    /// 签名规则: MD5(appID + query + salt + secretKey)
    private func generateSign(text: String, appID: String, salt: String, key: String) -> String {
        // 对文本进行 URL 编码
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text

        // 拼接字符串
        let signString = appID + encodedText + salt + key

        // MD5 加密
        return signString.md5
    }

    /// 解析百度 API 响应
    private func parseResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ServiceError.parseError
        }

        // 检查错误码
        if let errorCode = json["error_code"] as? Int,
           let errorMsg = json["error_msg"] as? String {
            throw ServiceError.translationFailed("百度 API 错误 \(errorCode): \(errorMsg)")
        }

        guard let transResult = json["trans_result"] as? [[String: Any]],
              let firstResult = transResult.first,
              let dst = firstResult["dst"] as? String else {
            throw ServiceError.parseError
        }

        guard !dst.isEmpty else {
            throw ServiceError.translationFailed("翻译结果为空")
        }

        return dst
    }

    // MARK: - Configuration

    /// 获取百度 App ID
    private func getAppID() -> String? {
        return UserDefaults.standard.string(forKey: "baidu_appId")
    }

    /// 获取百度密钥
    private func getSecretKey() -> String? {
        return UserDefaults.standard.string(forKey: "baidu_secretKey")
    }
}

// MARK: - Configuration Management

extension BaiduTranslationService {
    /// 保存百度 API 配置
    func saveConfig(appID: String, secretKey: String) -> Bool {
        guard !appID.isEmpty, !secretKey.isEmpty else { return false }
        UserDefaults.standard.set(appID, forKey: "baidu_appId")
        UserDefaults.standard.set(secretKey, forKey: "baidu_secretKey")
        return true
    }

    /// 检查是否有配置
    func hasConfig() -> Bool {
        guard let appID = getAppID(), !appID.isEmpty else { return false }
        guard let key = getSecretKey(), !key.isEmpty else { return false }
        return true
    }
}

// MARK: - String MD5 Extension

extension String {
    var md5: String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { bytes in
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
