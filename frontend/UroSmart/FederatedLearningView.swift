import SwiftUI

struct FederatedLearningView: View {
    @StateObject private var viewModel = FederatedLearningViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Status Card
                    statusCard
                    
                    // Training Data Section
                    trainingDataSection
                    
                    // Actions
                    actionsSection
                    
                    // Privacy Information
                    privacySection
                }
                .padding()
            }
            .navigationTitle("Federated Learning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Training Complete", isPresented: $viewModel.showTrainingComplete) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Local training completed successfully. Your corrections have been saved locally.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Collaborative Learning")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Help improve detection accuracy while keeping your data private")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Model Status")
                    .font(.headline)
            }
            
            Divider()
            
            HStack {
                Text("Model Version:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.modelVersion)")
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("Training Samples:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.trainingSampleCount)")
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.trainingSampleCount >= 10 ? .green : .orange)
            }
            
            HStack {
                Text("Last Update:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.lastUpdateDate)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var trainingDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Data Collection")
                .font(.headline)
            
            Text("Collect labeled samples to improve the model. Each correction you make helps train the AI.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(viewModel.trainingSampleCount), total: 10.0)
                .tint(.blue)
            
            Text("\(viewModel.trainingSampleCount)/10 samples needed for local training")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Start Local Training
            Button(action: {
                viewModel.startLocalTraining()
            }) {
                HStack {
                    if viewModel.isTraining {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "cpu")
                    }
                    Text(viewModel.isTraining ? "Training..." : "Start Local Training")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canStartTraining ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.canStartTraining || viewModel.isTraining)
            
            // Aggregate Updates
            Button(action: {
                viewModel.aggregateUpdates()
            }) {
                HStack {
                    if viewModel.isAggregating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(viewModel.isAggregating ? "Aggregating..." : "Aggregate Local Updates")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.isAggregating)
        }
    }
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.green)
                Text("Privacy Guaranteed")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                privacyPoint(icon: "checkmark.circle.fill", text: "Images never leave your device")
                privacyPoint(icon: "checkmark.circle.fill", text: "Only model weights are shared")
                privacyPoint(icon: "checkmark.circle.fill", text: "Your data remains anonymous")
                privacyPoint(icon: "checkmark.circle.fill", text: "Full control over participation")
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func privacyPoint(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - ViewModel

class FederatedLearningViewModel: ObservableObject {
    @Published var modelVersion: Int = 0
    @Published var trainingSampleCount: Int = 0
    @Published var lastUpdateDate: String = "Never"
    @Published var isTraining: Bool = false
    @Published var isAggregating: Bool = false
    @Published var showTrainingComplete: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    private let federatedManager = FederatedLearningManager.shared
    
    var canStartTraining: Bool {
        return trainingSampleCount >= AppConfig.minTrainingSamples && !isTraining
    }
    
    init() {
        loadStatus()
        setupNotifications()
    }
    
    private func loadStatus() {
        modelVersion = UserDefaults.standard.integer(forKey: "model_version")
        trainingSampleCount = TrainingDataStore.shared.sampleCount
        
        if let lastUpdate = UserDefaults.standard.object(forKey: "last_model_update") as? Date {
            let formatter = RelativeDateTimeFormatter()
            lastUpdateDate = formatter.localizedString(for: lastUpdate, relativeTo: Date())
        } else {
            lastUpdateDate = "Never"
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .readyForLocalTraining,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.trainingSampleCount = TrainingDataStore.shared.sampleCount
        }
        
        NotificationCenter.default.addObserver(
            forName: .globalModelUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadStatus()
        }
    }
    
    func startLocalTraining() {
        guard !isTraining else { return }
        isTraining = true
        
        federatedManager.startLocalTraining { [weak self] result in
            DispatchQueue.main.async {
                self?.isTraining = false
                
                switch result {
                case .success:
                    self?.trainingSampleCount = TrainingDataStore.shared.sampleCount
                    self?.showTrainingComplete = true
                    self?.loadStatus()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                }
            }
        }
    }
    
    func aggregateUpdates() {
        guard !isAggregating else { return }
        isAggregating = true
        
        federatedManager.aggregateNow { [weak self] success in
            DispatchQueue.main.async {
                self?.isAggregating = false
                if success {
                    self?.loadStatus()
                } else {
                    self?.errorMessage = "No local updates available for aggregation."
                    self?.showError = true
                }
            }
        }
    }
}

#Preview {
    FederatedLearningView()
}

