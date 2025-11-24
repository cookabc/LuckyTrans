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
        
        let apiEndpoint = SettingsManager.shared.apiEndpoint
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
        
        let modelName = SettingsManager.shared.modelName
        let request = TranslationRequest(text: text, targetLanguage: targetLanguage, model: modelName)
        
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
                    let translationResponse = try JSONDecoder().decode(TranslationResponse.self, from: data)
                    if let translation = translationResponse.translation {
                        return translation.trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        // 调试信息：打印响应内容
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Translation API Response (empty translation): \(responseString)")
                        }
                        throw TranslationError(error: TranslationError.ErrorDetail(
                            message: "翻译结果为空，请检查 API 响应格式",
                            type: "api_error",
                            code: nil
                        ))
                    }
                } catch let decodeError {
                    // 调试信息：打印解码错误和响应内容
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Translation API Response (decode error): \(responseString)")
                    }
                    throw TranslationError(error: TranslationError.ErrorDetail(
                        message: "无法解析 API 响应: \(decodeError.localizedDescription)",
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
                    helpfulHint = "\n提示: 请检查 API 端点是否正确。OpenAI API 端点应为: https://api.openai.com/v1/chat/completions"
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

