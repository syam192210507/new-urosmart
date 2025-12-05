import Foundation

/// Stores local FL updates and performs FedAvg aggregation (offline)
class LocalAggregationStore {

    static let shared = LocalAggregationStore()

    private init() {
        loadStoredUpdates()
    }

    // MARK: - Storage
    private var updateQueue: [LocalModelUpdate] = []
    private let queueFileName = "fl_update_queue.json"

    // MARK: Save update
    func save(update: LocalModelUpdate) {
        updateQueue.append(update)

        // Optional: limit stored updates
        if updateQueue.count > 50 {
            updateQueue.removeFirst(updateQueue.count - 50)
        }

        persist()
        print("📦 Saved local model update. Count = \(updateQueue.count)")
    }

    // MARK: Aggregate Updates (FedAvg)
    func aggregateUpdates() throws -> GlobalModelUpdate? {
        guard !updateQueue.isEmpty else {
            print("ℹ️ No updates to aggregate.")
            return nil
        }

        print("🔄 Aggregating \(updateQueue.count) updates...")

        // Collect weight keys
        let keys = updateQueue.first?.weightUpdates.keys ?? [:].keys

        var aggregated: [String: [Double]] = [:]

        for key in keys {
            // sum vectors
            var sumVector: [Double] = []
            var isFirst = true

            for update in updateQueue {
                if let vector = update.weightUpdates[key] {
                    if isFirst {
                        sumVector = vector
                        isFirst = false
                    } else {
                        sumVector = zip(sumVector, vector).map(+)
                    }
                }
            }

            // average vector
            let count = Double(updateQueue.count)
            let avgVector = sumVector.map { $0 / count }
            aggregated[key] = avgVector
        }

        let global = GlobalModelUpdate(
            version: (updateQueue.last?.version ?? 0) + 1,
            weights: aggregated,
            participatingDevices: updateQueue.count,
            aggregationTimestamp: Date(),
            averageLoss: updateQueue.map { $0.trainingLoss }.reduce(0, +) / Double(updateQueue.count),
            averageAccuracy: updateQueue.map { $0.validationAccuracy }.reduce(0, +) / Double(updateQueue.count)
        )

        // Clear queue once aggregated
        updateQueue.removeAll()
        persist()

        print("✅ Aggregation complete → global version \(global.version)")
        return global
    }

    // MARK: Persistence
    private func persist() {
        do {
            let url = getQueueFileURL()
            let data = try JSONEncoder().encode(updateQueue)
            try data.write(to: url)
        } catch {
            print("❌ Failed to save update queue: \(error)")
        }
    }

    private func loadStoredUpdates() {
        let url = getQueueFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let data = try Data(contentsOf: url)
            updateQueue = try JSONDecoder().decode([LocalModelUpdate].self, from: data)
            print("📥 Loaded \(updateQueue.count) pending updates")
        } catch {
            print("⚠️ Failed to load update queue: \(error)")
        }
    }

    private func getQueueFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(queueFileName)
    }
}

// MARK: - Federated Learning Data Models

struct GroundTruthLabels: Codable {
    let yeast: Bool
    let triplePhosphate: Bool
    let calciumOxalate: Bool
    let squamousCells: Bool
    let uricAcid: Bool
}

struct TrainingSample: Codable {
    let id: UUID
    let imageData: Data
    let labels: GroundTruthLabels
    let timestamp: Date
    
    init(imageData: Data, labels: GroundTruthLabels, timestamp: Date = Date()) {
        self.id = UUID()
        self.imageData = imageData
        self.labels = labels
        self.timestamp = timestamp
    }
}

struct LocalModelUpdate: Codable {
    let version: Int
    let weightUpdates: [String: [Double]]
    let numSamples: Int
    let trainingLoss: Double
    let validationAccuracy: Double
    let timestamp: Date
    
    init(version: Int,
         weightUpdates: [String: [Double]],
         numSamples: Int,
         trainingLoss: Double,
         validationAccuracy: Double) {
        self.version = version
        self.weightUpdates = weightUpdates
        self.numSamples = numSamples
        self.trainingLoss = trainingLoss
        self.validationAccuracy = validationAccuracy
        self.timestamp = Date()
    }
}

struct GlobalModelUpdate: Codable {
    let version: Int
    let weights: [String: [Double]]
    let participatingDevices: Int
    let aggregationTimestamp: Date
    let averageLoss: Double
    let averageAccuracy: Double
}

// MARK: - Training Data Store

class TrainingDataStore {
    static let shared = TrainingDataStore()
    
    private var samples: [TrainingSample] = []
    private let fileName = "fl_training_samples.json"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        loadSamples()
    }
    
    var sampleCount: Int {
        samples.count
    }
    
    func addSample(_ sample: TrainingSample) {
        samples.append(sample)
        
        if samples.count > AppConfig.maxTrainingSamples {
            samples.removeFirst(samples.count - AppConfig.maxTrainingSamples)
        }
        
        saveSamples()
        
        NotificationCenter.default.post(
            name: .readyForLocalTraining,
            object: nil
        )
    }
    
    func getAllSamples() -> [TrainingSample] {
        samples
    }
    
    func clear() {
        samples.removeAll()
        saveSamples()
    }
    
    // MARK: - Persistence
    private func saveSamples() {
        do {
            let url = samplesFileURL()
            let data = try encoder.encode(samples)
            try data.write(to: url)
        } catch {
            print("⚠️ Failed to save training samples: \(error)")
        }
    }
    
    private func loadSamples() {
        let url = samplesFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            samples = try decoder.decode([TrainingSample].self, from: data)
        } catch {
            print("⚠️ Failed to load training samples: \(error)")
        }
    }
    
    private func samplesFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let readyForLocalTraining = Notification.Name("readyForLocalTraining")
    static let globalModelUpdated = Notification.Name("globalModelUpdated")
    static let modelShouldReload = Notification.Name("modelShouldReload")
}
