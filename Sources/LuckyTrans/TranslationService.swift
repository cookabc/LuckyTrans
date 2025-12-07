import Foundation

class TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    func translate(text: String, targetLanguage: String) async throws -> String {
        guard let apiKey = SettingsManager.shared.getAPIKey(), !apiKey.isEmpty else {
            throw TranslationError(error: TranslationError.ErrorDetail(
                message: "API Key 未配置，请在设置中配置 API Key",
                type: "configuration_error",
                code: nil
            ))
        }
        
        var apiEndpoint = SettingsManager.shared.apiEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果端点不以 /chat/completions 结尾，自动添加
        // 支持 OpenAI compatible API 的标准路径
        if !apiEndpoint.hasSuffix("/chat/completions") && !apiEndpoint.hasSuffix("/chat/completions/") {
            // 移除末尾的斜杠
            if apiEndpoint.hasSuffix("/") {
                apiEndpoint = String(apiEndpoint.dropLast())
            }
            // 检查是否已经有 /v1 或 /v4 等版本路径
            if apiEndpoint.contains("/v1/") || apiEndpoint.contains("/v4/") {
                // 如果已经有版本路径，直接添加 chat/completions
                apiEndpoint = apiEndpoint + "/chat/completions"
            } else if apiEndpoint.contains("/v1") || apiEndpoint.contains("/v4") {
                // 如果版本路径在末尾，添加 /chat/completions
                apiEndpoint = apiEndpoint + "/chat/completions"
            } else {
                // 如果没有版本路径，添加 /v1/chat/completions（OpenAI 标准）
                apiEndpoint = apiEndpoint + "/v1/chat/completions"
            }
        }
        
        guard let url = URL(string: apiEndpoint) else {
            throw TranslationError(error: TranslationError.ErrorDetail(
                message: "无效的 API 端点格式: \(apiEndpoint)",
                type: "configuration_error",
                code: nil
            ))
        }
        
        // 验证 URL 格式
        guard url.scheme == "https" || url.scheme == "http" else {
            throw TranslationError(error: TranslationError.ErrorDetail(
                message: "API 端点必须使用 http 或 https 协议: \(apiEndpoint)",
                type: "configuration_error",
                code: nil
            ))
        }
        
        // 调试信息：打印请求 URL
        print("Translation API Request URL: \(url.absoluteString)")
        print("Translation API Endpoint (original): \(SettingsManager.shared.apiEndpoint)")
        print("Translation API Endpoint (final): \(apiEndpoint)")
        
        let modelName = SettingsManager.shared.modelName
        let mode = SettingsManager.shared.translationMode
        let request = TranslationRequest(text: text, targetLanguage: targetLanguage, mode: mode, model: modelName)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw TranslationError(error: TranslationError.ErrorDetail(
                message: "请求编码失败: \(error.localizedDescription)",
                type: "encoding_error",
                code: nil
            ))
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError(error: TranslationError.ErrorDetail(
                    message: "无效的响应",
                    type: "network_error",
                    code: nil
                ))
            }
            
            // 调试信息：打印响应状态码
            print("Translation API Response Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                do {
                    // 调试信息：打印响应内容（用于排查兼容性问题）
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Translation API Response: \(responseString.prefix(500))")
                    }
                    
                    let translationResponse = try JSONDecoder().decode(TranslationResponse.self, from: data)
                    if let translation = translationResponse.translation, !translation.isEmpty {
                        return translation.trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        // 调试信息：打印响应内容
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Translation API Response (empty translation): \(responseString)")
                        }
                        throw TranslationError(error: TranslationError.ErrorDetail(
                            message: "翻译结果为空，请检查 API 响应格式。如果使用 GLM-4.6，请确保 API 端点正确配置",
                            type: "api_error",
                            code: nil
                        ))
                    }
                } catch let decodeError {
                    // 调试信息：打印解码错误和响应内容
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Translation API Response (decode error): \(responseString)")
                        print("Decode Error: \(decodeError)")
                    }
                    throw TranslationError(error: TranslationError.ErrorDetail(
                        message: "无法解析 API 响应: \(decodeError.localizedDescription)。请检查 API 响应格式是否兼容 OpenAI API",
                        type: "api_error",
                        code: nil
                    ))
                }
            } else {
                // 尝试解析错误响应
                var errorMessage = "API 请求失败，状态码: \(httpResponse.statusCode)"
                var helpfulHint = ""
                
                // 根据状态码提供有用的提示
                switch httpResponse.statusCode {
                case 404:
                    helpfulHint = "\n提示: API 端点不存在 (404)。\n" +
                    "• 如果使用 OpenAI API，端点应为: https://api.openai.com/v1/chat/completions\n" +
                    "• 如果使用其他兼容 API，请确保端点包含完整路径，例如: https://your-api.com/v1/chat/completions\n" +
                    "• 当前使用的端点: \(apiEndpoint)"
                case 401:
                    helpfulHint = "\n提示: API Key 可能无效或已过期，请检查 API Key 配置"
                case 403:
                    helpfulHint = "\n提示: API Key 没有权限访问此端点，请检查 API Key 权限"
                case 429:
                    helpfulHint = "\n提示: API 请求频率过高，请稍后再试"
                case 500...599:
                    helpfulHint = "\n提示: 服务器内部错误，请稍后再试"
                default:
                    break
                }
                
                // 调试信息：打印错误响应
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Translation API Error Response: \(responseString)")
                }
                
                if let errorResponse = try? JSONDecoder().decode(TranslationError.self, from: data) {
                    throw TranslationError(error: TranslationError.ErrorDetail(
                        message: errorResponse.error.message + helpfulHint,
                        type: errorResponse.error.type,
                        code: errorResponse.error.code
                    ))
                } else if let responseString = String(data: data, encoding: .utf8) {
                    // 尝试从响应中提取错误信息
                    let preview = String(responseString.prefix(200))
                    errorMessage = "API 错误 (状态码: \(httpResponse.statusCode)): \(preview)\(helpfulHint)"
                } else {
                    errorMessage = "API 错误 (状态码: \(httpResponse.statusCode))\(helpfulHint)"
                }
                
                throw TranslationError(error: TranslationError.ErrorDetail(
                    message: errorMessage,
                    type: "api_error",
                    code: String(httpResponse.statusCode)
                ))
            }
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError(error: TranslationError.ErrorDetail(
                message: "网络请求失败: \(error.localizedDescription)",
                type: "network_error",
                code: nil
            ))
        }
    }
}
