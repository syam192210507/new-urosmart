import Foundation
import TensorFlowLite
import UIKit
import CoreGraphics

enum TFLiteError: Error {
    case loadFailed(String)
    case inferenceFailed(String)
}

final class TFLiteWrapper {
    private var interpreter: Interpreter
    private(set) var inputShape: [Int] = []
    
    // YOLOv8 Constants
    private let inputWidth = 640
    private let inputHeight = 640
    private let classCount = 5 // Triple Phosphate, Yeast, Calcium Oxalate, Squamous Cells, Uric Acid
    private let outputRows = 8400 // YOLOv8 output grid size
    
    init?(modelName: String = "best") {
        guard let path = Bundle.main.path(forResource: modelName, ofType: "tflite") else {
            print("⚠️ TFLite model \(modelName).tflite not found in bundle.")
            return nil
        }
        
        var options = Interpreter.Options()
        options.threadCount = 2
        
        do {
            interpreter = try Interpreter(modelPath: path, options: options)
            try interpreter.allocateTensors()
            
            let input = try interpreter.input(at: 0)
            inputShape = input.shape.dimensions
            print("✅ TFLite model loaded. Expected input shape: \(inputShape)")
        } catch {
            print("⚠️ Failed to load TFLite model: \(error)")
            return nil
        }
    }

    // MARK: - YOLO Inference
    func runInferenceYOLO(on image: UIImage) -> [ObjectDetection] {
        guard let inputData = preprocess(image, width: inputWidth, height: inputHeight) else {
            print("❌ Failed to preprocess image")
            return []
        }
        
        do {
            try interpreter.copy(inputData, toInputAt: 0)
            try interpreter.invoke()
            
            let outputTensor = try interpreter.output(at: 0)
            let outputData = outputTensor.data.toArray(type: Float.self)
            
            return postprocess(outputData)
        } catch {
            print("❌ Inference failed: \(error)")
            return []
        }
    }
    
    // MARK: - Preprocessing
    private func preprocess(_ image: UIImage, width: Int, height: Int) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return nil }
        
        // Convert to Float32 and Normalize [0, 1]
        var floatData = [Float]()
        let ptr = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        for i in 0..<(width * height) {
            let r = Float(ptr[i * 4]) / 255.0
            let g = Float(ptr[i * 4 + 1]) / 255.0
            let b = Float(ptr[i * 4 + 2]) / 255.0
            floatData.append(contentsOf: [r, g, b])
        }
        
        return floatData.withUnsafeBufferPointer { Data(buffer: $0) }
    }
    
    // MARK: - Postprocessing (NMS)
    private func postprocess(_ data: [Float]) -> [ObjectDetection] {
        // YOLOv8 Output: [1, 9, 8400] -> flattened
        // 9 channels: [x, y, w, h, class0, class1, class2, class3, class4]
        
        print("🔍 Starting YOLO postprocessing...")
        print("📊 Output data size: \(data.count)")
        
        var detections: [DetectionCandidate] = []
        let confThreshold: Float = 0.15  // Lowered to 0.15 to capture faint detections
        
        // Stride through the 8400 predictions
        // The output is transposed in TFLite usually, but let's assume [1, 9, 8400] flattened
        // Actually, TFLite export might be [1, 8400, 9] or [1, 9, 8400].
        // Based on verification script: Output shape: (1, 9, 8400)
        // So we have 9 rows, 8400 columns.
        // Data is row-major.
        
        let numClasses = 5
        let numFeatures = 4 + numClasses // 9
        let numPredictions = 8400
        
        print("🎯 Detection threshold: \(confThreshold)")
        print("📐 Expected data size: \(numFeatures * numPredictions) = \(9 * 8400)")
        
        for i in 0..<numPredictions {
            // Extract class scores
            var maxConf: Float = 0.0
            var bestClassIdx = 0
            
            for c in 0..<numClasses {
                // Access data[4 + c][i]
                // Index = (4 + c) * 8400 + i
                let conf = data[(4 + c) * numPredictions + i]
                if conf > maxConf {
                    maxConf = conf
                    bestClassIdx = c
                }
            }
            
            if maxConf > confThreshold {
                // print("Found candidate with conf: \(maxConf) class: \(bestClassIdx)")
                // Extract Box
                // x: data[0][i], y: data[1][i], w: data[2][i], h: data[3][i]
                let cx = data[0 * numPredictions + i]
                let cy = data[1 * numPredictions + i]
                let w = data[2 * numPredictions + i]
                let h = data[3 * numPredictions + i]
                
                let x = cx - w/2
                let y = cy - h/2
                
                detections.append(DetectionCandidate(
                    classIndex: bestClassIdx,
                    confidence: maxConf,
                    rect: CGRect(x: Double(x), y: Double(y), width: Double(w), height: Double(h))
                ))
            }
        }
        
        print("✅ Found \(detections.count) raw detections above threshold")
        
        // Apply NMS
        let nmsDetections = nonMaxSuppression(detections, iouThreshold: 0.45)
        print("📦 After NMS: \(nmsDetections.count) detections remaining")
        
        // Group by class
        var results: [ObjectDetection] = []
        // CRITICAL: This order MUST match the training data.yaml file
        // data.yaml order: ['calcium_oxalate', 'squamous_cells', 'triple_phosphate', 'uric_acid', 'yeast']
        let classNames = ["Calcium Oxalate", "Squamous Cells", "Triple Phosphate", "Uric Acid", "Yeast"]
        
        for classIdx in 0..<numClasses {
            let classDetections = nmsDetections.filter { $0.classIndex == classIdx }
            if !classDetections.isEmpty {
                // Normalize coordinates by input size (640) for display
                let boxes = classDetections.map { d in
                    let x1 = d.rect.origin.x
                    let y1 = d.rect.origin.y
                    let x2 = (d.rect.origin.x + d.rect.size.width)
                    let y2 = (d.rect.origin.y + d.rect.size.height)
                    return [x1, y1, x2, y2]
                }
                let avgConf = classDetections.reduce(0.0) { $0 + Double($1.confidence) } / Double(classDetections.count)
                
                // Convert CGFloat boxes to Double boxes
                let doubleBoxes = boxes.map { box in
                    box.map { Double($0) }
                }
                
                print("  ✅ \(classNames[classIdx]): \(classDetections.count) detections, avg confidence: \(String(format: "%.2f", avgConf))")
                
                results.append(ObjectDetection(
                    name: classNames[classIdx],
                    present: true,
                    confidence: avgConf,
                    boundingBoxes: doubleBoxes
                ))
            } else {
                results.append(ObjectDetection(name: classNames[classIdx], present: false, confidence: 0.0, boundingBoxes: []))
            }
        }
        
        print("🎉 Final results: \(results.filter { $0.present }.count) types detected")
        
        return results
    }
    
    private func nonMaxSuppression(_ detections: [DetectionCandidate], iouThreshold: Float) -> [DetectionCandidate] {
        let sorted = detections.sorted { $0.confidence > $1.confidence }
        var selected: [DetectionCandidate] = []
        var active = Array(repeating: true, count: sorted.count)
        
        for i in 0..<sorted.count {
            if active[i] {
                let boxA = sorted[i]
                selected.append(boxA)
                
                for j in (i+1)..<sorted.count {
                    if active[j] {
                        let boxB = sorted[j]
                        // Only compare boxes of same class
                        if boxA.classIndex == boxB.classIndex {
                            let iou = calculateIoU(boxA.rect, boxB.rect)
                            if iou > Double(iouThreshold) {
                                active[j] = false
                            }
                        }
                    }
                }
            }
        }
        return selected
    }
    
    private func calculateIoU(_ rect1: CGRect, _ rect2: CGRect) -> Double {
        let intersection = rect1.intersection(rect2)
        if intersection.isNull { return 0.0 }
        
        let intersectArea = intersection.width * intersection.height
        let unionArea = rect1.width * rect1.height + rect2.width * rect2.height - intersectArea
        
        return Double(intersectArea / unionArea)
    }
}

struct DetectionCandidate {
    let classIndex: Int
    let confidence: Float
    let rect: CGRect
}

// MARK: - Data Converter Helper
fileprivate extension Data {
    func toArray<T>(type: T.Type) -> [T] {
        let count = self.count / MemoryLayout<T>.size
        return withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [T] in
            let typedPtr = ptr.bindMemory(to: T.self)
            return Array(typedPtr.prefix(count))
        }
    }
}
