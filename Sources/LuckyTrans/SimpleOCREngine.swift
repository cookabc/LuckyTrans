import Foundation
import AppKit
import Vision

/// 简化的 OCR 引擎，用于从图像中识别文本
///
/// 功能特性：
/// - 支持中文和英文识别
/// - 自动语言检测
/// - 智能文本合并
/// - 异步处理，不阻塞主线程
@MainActor
public class SimpleOCREngine: NSObject {
    // MARK: - Singleton

    public static let shared = SimpleOCREngine()

    // MARK: - Properties

    /// 支持的识别语言
    public enum RecognitionLanguage {
        case auto        // 自动检测
        case chinese     // 中文
        case english     // 英文
        case chineseEnglish  // 中英混合

        var recognitionLanguages: [String] {
            switch self {
            case .auto:
                return []
            case .chinese:
                return ["zh-Hans"]
            case .english:
                return ["en"]
            case .chineseEnglish:
                return ["zh-Hans", "en"]
            }
        }
    }

    /// OCR 配置
    public struct Configuration {
        /// 识别语言
        var language: RecognitionLanguage = .auto

        /// 是否使用语言修正（提高准确率但可能改变识别结果）
        var usesLanguageCorrection: Bool = true

        /// 识别级别
        var recognitionLevel: VNRequestTextRecognitionLevel = .accurate

        /// 最小置信度阈值
        var minimumConfidence: Float = 0.0

        public static let `default` = Configuration()
    }

    private var currentConfiguration: Configuration = .default

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// 从图像中识别文本
    ///
    /// - Parameters:
    ///   - image: 要识别的图像
    ///   - language: 识别语言（默认自动）
    /// - Returns: OCR 识别结果
    public func recognizeText(from image: NSImage, language: RecognitionLanguage = .auto) async throws -> OCRResult {
        // 验证图像
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) ??
                    image.toCGImage() else {
            throw OCRError.invalidImage
        }

        // 创建 OCR 请求
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR Request error: \(error.localizedDescription)")
            }
        }

        // 配置请求
        request.recognitionLevel = currentConfiguration.recognitionLevel
        request.usesLanguageCorrection = currentConfiguration.usesLanguageCorrection

        // 设置识别语言
        if language != .auto {
            request.recognitionLanguages = language.recognitionLanguages
            request.automaticallyDetectsLanguage = false
        } else {
            request.automaticallyDetectsLanguage = true
        }

        // 执行识别
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw OCRError.processingFailed(error.localizedDescription)
        }

        // 处理结果
        guard let observations = request.results as? [VNRecognizedTextObservation],
              !observations.isEmpty else {
            throw OCRError.noTextFound
        }

        // 过滤低置信度结果
        let filteredObservations = observations.filter { observation in
            guard let candidate = observation.topCandidates(1).first else { return false }
            return candidate.confidence >= currentConfiguration.minimumConfidence
        }

        if filteredObservations.isEmpty {
            throw OCRError.noTextFound
        }

        // 转换为结果
        return processObservations(filteredObservations)
    }

    /// 从剪贴板图像识别文本
    public func recognizeTextFromPasteboard() async throws -> OCRResult {
        guard let imageData = NSPasteboard.general.data(forType: .png) ??
                              NSPasteboard.general.data(forType: .tiff) else {
            throw OCRError.invalidImage
        }

        guard let image = NSImage(data: imageData) else {
            throw OCRError.invalidImage
        }

        return try await recognizeText(from: image)
    }

    /// 更新配置
    public func updateConfiguration(_ config: Configuration) {
        self.currentConfiguration = config
    }

    // MARK: - Private Methods

    /// 处理 OCR 观测结果
    private func processObservations(_ observations: [VNRecognizedTextObservation]) -> OCRResult {
        // 按位置排序（从上到下，从左到右）
        let sortedObservations = sortObservations(observations)

        var texts: [String] = []
        var totalConfidence: Double = 0

        for observation in sortedObservations {
            if let candidate = observation.topCandidates(1).first {
                texts.append(candidate.string)
                totalConfidence += Double(candidate.confidence)
            }
        }

        // 合并文本
        let mergedText = mergeTexts(texts, observations: sortedObservations)

        // 计算平均置信度
        let averageConfidence = texts.isEmpty ? 0.0 : totalConfidence / Double(texts.count)

        // 检测语言
        let detectedLanguage = detectLanguage(from: mergedText)

        return OCRResult(
            texts: texts,
            mergedText: mergedText,
            confidence: averageConfidence
        )
    }

    /// 对观测结果进行空间排序
    private func sortObservations(_ observations: [VNRecognizedTextObservation]) -> [VNRecognizedTextObservation] {
        return observations.sorted { obs1, obs2 in
            let box1 = obs1.boundingBox
            let box2 = obs2.boundingBox

            // Vision 坐标系：原点在左下角
            // Y 坐标较大的在上面

            // 判断是否在同一行（Y 坐标接近）
            let yThreshold: CGFloat = 0.02  // 可根据需要调整
            let isSameLine = abs(box1.origin.y - box2.origin.y) < yThreshold

            if isSameLine {
                // 同一行按 X 坐标排序（从左到右）
                return box1.origin.x < box2.origin.x
            } else {
                // 不同行按 Y 坐标排序（从上到下）
                return box1.origin.y > box2.origin.y
            }
        }
    }

    /// 智能合并文本行
    private func mergeTexts(_ texts: [String], observations: [VNRecognizedTextObservation]) -> String {
        guard !texts.isEmpty else { return "" }

        // 如果只有一行，直接返回
        if texts.count == 1 {
            return texts[0]
        }

        var result: [String] = []

        for (index, text) in texts.enumerated() {
            if index > 0 {
                let prevText = texts[index - 1]
                let prevBox = observations[index - 1].boundingBox
                let currentBox = observations[index].boundingBox

                // 计算行间距
                let yGap = abs(prevBox.origin.y - currentBox.origin.y)

                // 计算字符高度作为参考
                let charHeight = prevBox.height

                // 如果间距大于字符高度的 1.5 倍，视为段落间隔
                if yGap > charHeight * 1.5 {
                    // 添加段落间隔
                    result.append("\n")
                } else if shouldAppendWithSpace(prevText, text) {
                    // 同一行需要空格连接
                    result.append(" ")
                } else {
                    // 普通换行
                    result.append("\n")
                }
            }

            result.append(text)
        }

        return result.joined()
    }

    /// 判断两个文本片段是否需要空格连接
    private func shouldAppendWithSpace(_ prev: String, _ current: String) -> Bool {
        // 中文之间不需要空格
        let prevIsChinese = prev.unicodeScalars.last.map { $0.properties.isEmoji ? false : $0.value >= 0x4E00 && $0.value <= 0x9FFF } ?? false
        let currentIsChinese = current.unicodeScalars.first.map { $0.value >= 0x4E00 && $0.value <= 0x9FFF } ?? false

        if prevIsChinese || currentIsChinese {
            return false
        }

        // 英文单词之间通常需要空格
        return true
    }

    /// 简单的语言检测
    private func detectLanguage(from text: String) -> String {
        guard !text.isEmpty else { return "unknown" }

        var chineseCount = 0
        var englishCount = 0

        for scalar in text.unicodeScalars {
            let value = scalar.value
            if value >= 0x4E00 && value <= 0x9FFF {
                chineseCount += 1
            } else if (value >= 0x0041 && value <= 0x005A) || (value >= 0x0061 && value <= 0x007A) {
                englishCount += 1
            }
        }

        let total = chineseCount + englishCount
        if total == 0 { return "unknown" }

        let chineseRatio = Double(chineseCount) / Double(total)

        if chineseRatio > 0.3 {
            return "zh"
        } else {
            return "en"
        }
    }
}

// MARK: - NSImage Extension

extension NSImage {
    /// 将 NSImage 转换为 CGImage
    func toCGImage() -> CGImage? {
        let width = self.size.width
        let height = self.size.height

        // 创建 bitmap
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(width),
            pixelsHigh: Int(height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }

        // 绘制图像到 bitmap
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current = context
        self.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()

        return bitmap.cgImage
    }
}
