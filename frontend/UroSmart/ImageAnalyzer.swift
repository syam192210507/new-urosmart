import UIKit
import TensorFlowLite     // ✅ REQUIRED

// MARK: - Detection Models

struct ObjectDetection: Codable {
    let name: String
    let present: Bool
    let confidence: Double
    let boundingBoxes: [[Double]]? // [x, y, width, height]
    
    init(name: String, present: Bool, confidence: Double, boundingBoxes: [[Double]]? = nil) {
        self.name = name
        self.present = present
        self.confidence = confidence
        self.boundingBoxes = boundingBoxes
    }
}

struct AnalysisResult: Codable {
    let yeast: ObjectDetection
    let triplePhosphate: ObjectDetection
    let calciumOxalate: ObjectDetection
    let squamousCells: ObjectDetection
    let uricAcid: ObjectDetection
    
    var totalObjects: Int {
        [yeast, triplePhosphate, calciumOxalate, squamousCells, uricAcid]
            .filter { $0.present }
            .reduce(0) { count, detection in
                // Use bounding box count if available, otherwise 1 if present
                if let boxes = detection.boundingBoxes, !boxes.isEmpty {
                    return count + boxes.count
                }
                return count + (detection.present ? 1 : 0)
            }
    }
    
    var present: Bool {
        totalObjects > 0
    }
}

// MARK: - Analyzer

final class ImageAnalyzer {
    private let tfliteWrapper: TFLiteWrapper?
    
    init() {
        // Use 'best' model which is the full YOLO detector (640x640 -> [1,9,8400])
        // NOT 'head' which is a simple classifier (128x128 -> [1,5])
        tfliteWrapper = TFLiteWrapper(modelName: "best")
    }
    
    func analyzeAsync(_ image: UIImage) async -> AnalysisResult {
        // Try online analysis first (for bounding boxes)
        if let onlineResult = await analyzeOnline(image) {
            return onlineResult
        }
        
        // Fallback to offline TFLite (YOLOv8)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let wrapper = self.tfliteWrapper else {
                    // Return empty result if wrapper fails
                    continuation.resume(returning: AnalysisResult(
                        yeast: ObjectDetection(name: "Yeast", present: false, confidence: 0),
                        triplePhosphate: ObjectDetection(name: "Triple Phosphate", present: false, confidence: 0),
                        calciumOxalate: ObjectDetection(name: "Calcium Oxalate", present: false, confidence: 0),
                        squamousCells: ObjectDetection(name: "Squamous Cells", present: false, confidence: 0),
                        uricAcid: ObjectDetection(name: "Uric Acid", present: false, confidence: 0)
                    ))
                    return
                }
                
                let detections = wrapper.runInferenceYOLO(on: image)
                
                // Map [ObjectDetection] to AnalysisResult
                let yeast = detections.first(where: { $0.name == "Yeast" }) ?? ObjectDetection(name: "Yeast", present: false, confidence: 0)
                let triple = detections.first(where: { $0.name == "Triple Phosphate" }) ?? ObjectDetection(name: "Triple Phosphate", present: false, confidence: 0)
                let calcium = detections.first(where: { $0.name == "Calcium Oxalate" }) ?? ObjectDetection(name: "Calcium Oxalate", present: false, confidence: 0)
                let squamous = detections.first(where: { $0.name == "Squamous Cells" }) ?? ObjectDetection(name: "Squamous Cells", present: false, confidence: 0)
                let uric = detections.first(where: { $0.name == "Uric Acid" }) ?? ObjectDetection(name: "Uric Acid", present: false, confidence: 0)
                
                let result = AnalysisResult(
                    yeast: yeast,
                    triplePhosphate: triple,
                    calciumOxalate: calcium,
                    squamousCells: squamous,
                    uricAcid: uric
                )
                
                continuation.resume(returning: result)
            }
        }
    }
    
    private func analyzeOnline(_ image: UIImage) async -> AnalysisResult? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let url = URL(string: "\(AppConfig.apiBaseURL)/detect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 3.0  // 3 second timeout for quick fallback
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add confidence parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"confidence\"\r\n\r\n".data(using: .utf8)!)
        body.append("0.15\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("⚠️ Backend analysis failed")
                return nil
            }
            
            // Parse backend response
            struct BackendResponse: Decodable {
                struct DetectionResults: Decodable {
                    struct ClassResult: Decodable {
                        struct Box: Decodable {
                            let bbox: [Double]
                            let confidence: Double
                        }
                        let present: Bool
                        let confidence: Double
                        let detections: [Box]
                    }
                    let results: [String: ClassResult]
                }
                let detection_results: DetectionResults
            }
            
            let decoded = try JSONDecoder().decode(BackendResponse.self, from: data)
            let results = decoded.detection_results.results
            
            func mapDetection(key: String, name: String) -> ObjectDetection {
                if let result = results[key] {
                    let boxes = result.detections.map { $0.bbox }
                    return ObjectDetection(
                        name: name,
                        present: result.present,
                        confidence: result.confidence,
                        boundingBoxes: boxes
                    )
                }
                return ObjectDetection(name: name, present: false, confidence: 0)
            }
            
            print("✅ Online analysis successful with bounding boxes")
            
            return AnalysisResult(
                yeast: mapDetection(key: "yeast", name: "Yeast"),
                triplePhosphate: mapDetection(key: "triple_phosphate", name: "Triple Phosphate"),
                calciumOxalate: mapDetection(key: "calcium_oxalate", name: "Calcium Oxalate"),
                squamousCells: mapDetection(key: "squamous_cells", name: "Squamous Cells"),
                uricAcid: mapDetection(key: "uric_acid", name: "Uric Acid")
            )
            
        } catch {
            print("⚠️ Online analysis error: \(error)")
            return nil
        }
    }
    
    // Removed old analyze() and buildResult() as they relied on the deprecated predict() method
    
    private func heuristicAnalysis(image: UIImage) -> AnalysisResult {
        guard let data = image.grayscaleData() else {
            return emptyResult()
        }
        
        let stats = imageStatistics(from: data)
        
        func makeDetection(name: String, score: Double) -> ObjectDetection {
            ObjectDetection(
                name: name,
                present: score >= 0.5,
                confidence: score
            )
        }
        
        return AnalysisResult(
            yeast: makeDetection(name: "Yeast", score: stats.texture * stats.brightness),
            triplePhosphate: makeDetection(name: "Triple Phosphate", score: stats.edgeDensity),
            calciumOxalate: makeDetection(name: "Calcium Oxalate", score: stats.contrast),
            squamousCells: makeDetection(name: "Squamous Cells", score: stats.brightness * 0.8),
            uricAcid: makeDetection(name: "Uric Acid", score: stats.texture * 0.7)
        )
    }
    
    private func imageStatistics(from buffer: GrayscaleBuffer) -> (brightness: Double, contrast: Double, edgeDensity: Double, texture: Double) {
        let pixels = buffer.pixels
        let count = Double(pixels.count)
        
        guard count > 0 else { return (0, 0, 0, 0) }
        
        let brightness = pixels.reduce(0.0) { $0 + Double($1) } / (255.0 * count)
        
        let mean = pixels.reduce(0.0) { $0 + Double($1) } / count
        let variance = pixels.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / count
        let contrast = min(1.0, sqrt(variance) / 255.0)
        
        var edgeCount = 0
        for y in 1..<buffer.height-1 {
            for x in 1..<buffer.width-1 {
                let idx = y * buffer.width + x
                let gx = Int(pixels[idx + 1]) - Int(pixels[idx - 1])
                let gy = Int(pixels[idx + buffer.width]) - Int(pixels[idx - buffer.width])
                if abs(gx) + abs(gy) > 60 {
                    edgeCount += 1
                }
            }
        }
        let edgeDensity = min(1.0, Double(edgeCount) / count)
        
        var transitions = 0
        for i in 1..<pixels.count {
            if abs(Int(pixels[i]) - Int(pixels[i - 1])) > 30 {
                transitions += 1
            }
        }
        let texture = min(1.0, Double(transitions) / count)
        
        return (brightness, contrast, edgeDensity, texture)
    }
    
    private func emptyResult() -> AnalysisResult {
        AnalysisResult(
            yeast: ObjectDetection(name: "Yeast", present: false, confidence: 0),
            triplePhosphate: ObjectDetection(name: "Triple Phosphate", present: false, confidence: 0),
            calciumOxalate: ObjectDetection(name: "Calcium Oxalate", present: false, confidence: 0),
            squamousCells: ObjectDetection(name: "Squamous Cells", present: false, confidence: 0),
            uricAcid: ObjectDetection(name: "Uric Acid", present: false, confidence: 0)
        )
    }
}

private struct GrayscaleBuffer {
    let pixels: [UInt8]
    let width: Int
    let height: Int
}

private extension UIImage {
    func normalizedInput(size: CGSize) -> [Float]? {
        guard let resized = resized(to: size),
              let cgImage = resized.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        var rawData = [UInt8](repeating: 0, count: Int(height * bytesPerRow))
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var floats: [Float] = []
        floats.reserveCapacity(width * height * 3)
        
        for idx in stride(from: 0, to: rawData.count, by: 4) {
            let r = Float(rawData[idx]) / 255.0
            let g = Float(rawData[idx + 1]) / 255.0
            let b = Float(rawData[idx + 2]) / 255.0
            floats.append(contentsOf: [r, g, b])
        }
        
        print("📊 Preprocessed image: \(width)x\(height) = \(floats.count) floats")
        return floats
    }
    
    func resized(to size: CGSize) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerRow = width * 4
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let outputImage = context.makeImage() else { return nil }
        // CRITICAL: Set scale to 1.0 to prevent 2x/3x scaling
        return UIImage(cgImage: outputImage, scale: 1.0, orientation: .up)
    }
    
    func grayscaleData() -> GrayscaleBuffer? {
        guard let resized = resized(to: CGSize(width: 128, height: 128)),
              let cgImage = resized.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width
        var pixels = [UInt8](repeating: 0, count: width * height)
        
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: 0
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return GrayscaleBuffer(pixels: pixels, width: width, height: height)
    }
}
