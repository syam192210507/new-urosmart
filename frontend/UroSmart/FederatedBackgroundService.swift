import Foundation
import UIKit

/// Background service that automatically checks for federated learning model updates
/// Starts after user login and runs periodically
class FederatedBackgroundService {
    static let shared = FederatedBackgroundService()
    
    private var isRunning = false
    private var currentModelVersion = 0
    private var timer: Timer?
    
    // Check for updates every 5 minutes (300 seconds)
    private let updateInterval: TimeInterval = 300
    
    private init() {}
    
    /// Start the background service (call after successful login)
    func start() {
        guard !isRunning else {
            print("⚠️ Federated service already running")
            return
        }
        
        isRunning = true
        print("✅ Federated service started")
        
        // Check immediately on start
        checkForUpdates()
        
        // Schedule periodic checks
        timer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkForUpdates()
        }
    }
    
    /// Stop the background service (call on logout)
    func stop() {
        guard isRunning else { return }
        
        timer?.invalidate()
        timer = nil
        isRunning = false
        print("🛑 Federated service stopped")
    }
    
    /// Check if new model updates are available and download if needed
    private func checkForUpdates() {
        Task {
            do {
                print("📡 Checking for model updates (current version: \(currentModelVersion))...")
                
                let updateCheck = try await NetworkService.shared.checkModelUpdates(
                    currentVersion: currentModelVersion
                )
                
                if updateCheck.has_update && updateCheck.online {
                    print("🆕 New model version \(updateCheck.latest_version) available!")
                    try await downloadAndApplyModel()
                } else {
                    print("✓ Model is up to date (v\(currentModelVersion))")
                }
                
            } catch NetworkError.unauthorized {
                print("⚠️ Not authorized - stopping federated service")
                stop()
            } catch NetworkError.offline {
                print("📴 Offline - will retry next interval")
            } catch {
                print("⚠️ Failed to check for updates: \(error.localizedDescription)")
            }
        }
    }
    
    /// Download the latest model from the server
    private func downloadAndApplyModel() async throws {
        print("⬇️ Downloading latest model...")
        
        let modelResponse = try await NetworkService.shared.getLatestModel()
        
        guard modelResponse.model_available,
              let version = modelResponse.version,
              let weights = modelResponse.weights else {
            print("⚠️ Model not available or incomplete")
            return
        }
        
        print("✅ Downloaded model v\(version)")
        print("   - Participating devices: \(modelResponse.participating_devices ?? 0)")
        print("   - Average accuracy: \(String(format: "%.2f%%", (modelResponse.average_accuracy ?? 0) * 100))")
        
        // Update current version
        currentModelVersion = version
        
        // FUTURE ENHANCEMENT: Apply weights to CoreML model
        // This requires CoreML weight update implementation
        // For now, we just log that we received the model
        print("📝 Model weights received (\(weights.count) layers)")
        print("ℹ️ Note: CoreML weight application is a future enhancement")
    }
    
    /// Submit local model updates (for future use when local training is implemented)
    func submitLocalUpdate(
        weightUpdates: [String: [Double]],
        numSamples: Int,
        trainingLoss: Double,
        validationAccuracy: Double
    ) async throws {
        let deviceId = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        print("📤 Submitting local model update...")
        
        let response = try await NetworkService.shared.submitModelUpdate(
            deviceId: deviceId,
            version: currentModelVersion,
            weightUpdates: weightUpdates,
            numSamples: numSamples,
            trainingLoss: trainingLoss,
            validationAccuracy: validationAccuracy
        )
        
        print("✅ Update submitted: \(response.status)")
        print("   Message: \(response.message)")
        
        if let newVersion = response.new_version {
            currentModelVersion = newVersion
        }
    }
}
