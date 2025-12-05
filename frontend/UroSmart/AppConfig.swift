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
    /// iPhone Testing: "http://172.25.81.32:5000/api" (Mac's IP)
    /// Production: "https://your-app.herokuapp.com/api"
    static let apiBaseURL = "http://172.25.81.32:5000/api"
    
    // MARK: - Federated Learning Backend Configuration
    
    /// Enable/disable federated learning (feature flag)
    static let enableFederatedLearning = true
    
    /// How often to check for model updates from server (in seconds)
    /// Default: 300 seconds = 5 minutes
    static let federatedUpdateInterval: TimeInterval = 300
}
