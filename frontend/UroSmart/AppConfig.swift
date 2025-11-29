import Foundation
import CoreGraphics

/// App configuration for OFFLINE Federated Learning (no backend)
struct AppConfig {

    // MARK: - Federated Learning Settings

    /// Minimum samples required before starting local training
    static let minTrainingSamples = 10

    /// Maximum number of stored local samples
    static let maxTrainingSamples = 100

    /// Local training epochs (placeholder; TFLite uses SGD per sample)
    static let localEpochs = 3

    /// Batch size for future use (not used with TFLite SGD)
    static let trainingBatchSize = 8

    // MARK: - Local Aggregation Settings

    /// Period for local aggregation (6 hours)
    static let modelSyncInterval: TimeInterval = 21600

    // MARK: - TFLite Model Specifications

    /// Output indices for updated head parameters in head.tflite
    static let tfliteParamOutputIndices: [Int] = [1, 2]

    /// Expected training image size
    static let trainingImageSize = CGSize(width: 640, height: 640)
    
    // MARK: - API Configuration
    
    /// Backend API URL (Update this for production!)
    /// Local: "http://localhost:5000/api"
    /// Production: "https://your-app.herokuapp.com/api"
    static let apiBaseURL = "http://127.0.0.1:5000/api"
}
