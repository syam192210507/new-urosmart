import Foundation
import UIKit

/// Fully offline Federated Learning Manager (NO backend, NO CoreML)
class FederatedLearningManager {

    static let shared = FederatedLearningManager()

    private let trainingDataStore = TrainingDataStore.shared
    private var currentModelVersion = 0
    private var isTraining = false
    private var syncTimer: Timer?

    private init() {
        loadModelVersion()
        startLocalAggregationTimer()
    }

    // MARK: - Collect Training Data
    func collectTrainingData(image: UIImage, labels: GroundTruthLabels) {
        let sample = TrainingSample(
            imageData: image.jpegData(compressionQuality: 0.9) ?? Data(),
            labels: labels,
            timestamp: Date()
        )

        trainingDataStore.addSample(sample)
        print("📥 Added training sample. Total: \(trainingDataStore.sampleCount)")

        if trainingDataStore.sampleCount >= AppConfig.minTrainingSamples {
            startLocalTraining()
        }
    }

    // MARK: - Local Training (Simulated TFLite Update)
    func startLocalTraining(completion: ((Result<LocalModelUpdate, Error>) -> Void)? = nil) {
        guard !isTraining else { return }
        guard trainingDataStore.sampleCount >= AppConfig.minTrainingSamples else { return }
        
        isTraining = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let update = try self.performLocalTraining()

                self.saveLocalModelUpdate(update)

                DispatchQueue.main.async {
                    self.isTraining = false
                    print("✅ Local FL training completed.")
                    completion?(.success(update))
                }

            } catch {
                DispatchQueue.main.async {
                    self.isTraining = false
                    print("❌ Local training failed: \(error)")
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Performs "simulated" local SGD-like update using your training samples
    private func performLocalTraining() throws -> LocalModelUpdate {
        let samples = trainingDataStore.getAllSamples()

        // Simulate simple federated gradient updates
        let updates = computeSimulatedWeightUpdates(samples: samples)

        return LocalModelUpdate(
            version: currentModelVersion,
            weightUpdates: updates,
            numSamples: samples.count,
            trainingLoss: 0.12,
            validationAccuracy: 0.86
        )
    }

    // MARK: - Local Aggregation Loop
    private func startLocalAggregationTimer() {
        syncTimer = Timer.scheduledTimer(
            withTimeInterval: AppConfig.modelSyncInterval,
            repeats: true
        ) { _ in
            self.aggregateLocalUpdates()
        }
    }

    func aggregateNow(completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let success = self.aggregateLocalUpdates()
            DispatchQueue.main.async { completion?(success) }
        }
    }
    
    @discardableResult
    private func aggregateLocalUpdates() -> Bool {
        do {
            if let aggregated = try LocalAggregationStore.shared.aggregateUpdates() {
                try applyGlobalModel(aggregated)
                print("🔄 Local model aggregated")
                return true
            }
        } catch {
            print("❌ Aggregation failed: \(error)")
        }
        return false
    }

    private func applyGlobalModel(_ global: GlobalModelUpdate) throws {
        try FederatedModelManager.shared.applyGlobalModelUpdate(global)
        saveModelVersion(global.version)

        UserDefaults.standard.set(Date(), forKey: "last_model_update")
        
        NotificationCenter.default.post(name: .globalModelUpdated, object: nil)
    }

    // MARK: - Store Local Updates
    private func saveLocalModelUpdate(_ update: LocalModelUpdate) {
        LocalAggregationStore.shared.save(update: update)
    }

    // MARK: - Version Sync
    private func saveModelVersion(_ version: Int) {
        currentModelVersion = version
        UserDefaults.standard.set(version, forKey: "model_version")
    }

    private func loadModelVersion() {
        currentModelVersion = UserDefaults.standard.integer(forKey: "model_version")
    }

    // MARK: - Simulated Federated Learning Update Logic
    private func computeSimulatedWeightUpdates(samples: [TrainingSample]) -> [String: [Double]] {
        guard !samples.isEmpty else {
            return [
                "yeast_weights": Array(repeating: 0.0, count: 10),
                "triple_phosphate_weights": Array(repeating: 0.0, count: 10),
                "calcium_oxalate_weights": Array(repeating: 0.0, count: 10),
                "squamous_cells_weights": Array(repeating: 0.0, count: 10),
                "uric_acid_weights": Array(repeating: 0.0, count: 10)
            ]
        }

        var counts = [
            "yeast": 0,
            "triple": 0,
            "calcium": 0,
            "squamous": 0,
            "uric": 0
        ]
        
        for sample in samples {
            if sample.labels.yeast { counts["yeast"]! += 1 }
            if sample.labels.triplePhosphate { counts["triple"]! += 1 }
            if sample.labels.calciumOxalate { counts["calcium"]! += 1 }
            if sample.labels.squamousCells { counts["squamous"]! += 1 }
            if sample.labels.uricAcid { counts["uric"]! += 1 }
        }
        
        let total = Double(samples.count)
        
        func norm(_ v: Int) -> [Double] {
            Array(repeating: Double(v) / total, count: 10)
        }

        return [
            "yeast_weights": norm(counts["yeast"]!),
            "triple_phosphate_weights": norm(counts["triple"]!),
            "calcium_oxalate_weights": norm(counts["calcium"]!),
            "squamous_cells_weights": norm(counts["squamous"]!),
            "uric_acid_weights": norm(counts["uric"]!)
        ]
    }
}
