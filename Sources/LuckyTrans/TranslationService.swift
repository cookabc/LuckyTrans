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
                message: "无效的 API 端点",
                type: "configuration_error",
                code: nil
            ))
        }
        
        let request = TranslationRequest(text: text, targetLanguage: targetLanguage)
        
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
                
                // 调试信息：打印错误响应
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Translation API Error Response: \(responseString)")
                }
                
                if let errorResponse = try? JSONDecoder().decode(TranslationError.self, from: data) {
                    throw errorResponse
                } else if let responseString = String(data: data, encoding: .utf8) {
                    // 尝试从响应中提取错误信息
                    let preview = String(responseString.prefix(200))
                    errorMessage = "API 错误 (状态码: \(httpResponse.statusCode)): \(preview)"
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

