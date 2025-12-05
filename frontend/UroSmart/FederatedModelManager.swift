import Foundation

/// Manages local federated learning model weights (TFLite head updates)
class FederatedModelManager {

    static let shared = FederatedModelManager()

    private init() {}

    // MARK: - Export backbone for training
    /// Returns the URL of the fixed backbone model (feature extractor)
    func exportModelForTraining() throws -> URL {
        guard let modelURL = Bundle.main.url(forResource: "feature_extractor", withExtension: "mlpackage") else {
            throw NSError(domain: "Model", code: -1, userInfo: [NSLocalizedDescriptionKey: "Feature extractor not found"])
        }
        return modelURL
    }

    // MARK: - Apply Federated Update
    func applyGlobalModelUpdate(_ update: GlobalModelUpdate) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(update)

        let url = getModelWeightsURL()
        try data.write(to: url)

        print("🧩 Global model updated & saved locally.")
    }

    // MARK: - Load saved update (for next inference)
    func loadSavedModelWeights() -> GlobalModelUpdate? {
        let url = getModelWeightsURL()

        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let update = try? JSONDecoder().decode(GlobalModelUpdate.self, from: data) else {
            return nil
        }
        return update
    }

    // MARK: - File location for saved weights
    private func getModelWeightsURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("fl_model_weights.json")
    }
}
