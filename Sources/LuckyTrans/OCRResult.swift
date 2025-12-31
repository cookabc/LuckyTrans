import Foundation
import AppKit

/// OCR 识别结果
public struct OCRResult {
    /// 识别出的所有文本行
    public var texts: [String] = []

    /// 合并后的完整文本
    public var mergedText: String = ""

    /// 置信度 (0.0 - 1.0)
    public var confidence: Double = 0.0

    /// 识别的语言
    public var detectedLanguage: String = ""

    /// 原始观测数据
    public var rawObservations: [Any] = []

    /// 是否为空结果
    public var isEmpty: Bool {
        return mergedText.isEmpty
    }

    /// 文本行数
    public var lineCount: Int {
        return texts.count
    }

    public init() {}

    public init(texts: [String], mergedText: String, confidence: Double = 0.0) {
        self.texts = texts
        self.mergedText = mergedText
        self.confidence = confidence
    }
}

/// OCR 错误类型
public enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case permissionDenied
    case processingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图像，请确保图像格式正确"
        case .noTextFound:
            return "未能识别出文本，请尝试更清晰的图像"
        case .permissionDenied:
            return "缺少必要的权限"
        case .processingFailed(let message):
            return "OCR 处理失败: \(message)"
        }
    }
}
