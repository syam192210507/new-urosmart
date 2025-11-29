import Foundation
import Combine

/// Syncs medical reports to backend when online
class ReportSyncService: ObservableObject {
    static let shared = ReportSyncService()
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date? = nil
    @Published var pendingUploads: Int = 0
    
    private let connectivity = ConnectivityMonitor.shared
    private let network = NetworkService.shared
    private let queueKey = "pending_reports_queue"
    
    private init() {
        // Load pending count
        pendingUploads = getPendingReports().count
    }
    
    // MARK: - Queue Management
    
    func queueReport(_ report: StoredReport) {
        var queue = getPendingReports()
        queue.append(report)
        savePendingReports(queue)
        
        let newCount = queue.count
        DispatchQueue.main.async {
            self.pendingUploads = newCount
        }
        
        print("📋 Queued report for sync: \(report.id)")
        
        // Try immediate sync if online
        if connectivity.isOnline {
            Task {
                await syncNow()
            }
        }
    }
    
    func syncNow() async {
        guard connectivity.isOnline else {
            print("📴 Offline - skipping sync")
            return
        }
        
        await MainActor.run {
            self.isSyncing = true
        }
        
        // 1. Upload pending reports
        var queue = getPendingReports()
        var syncedReports: [String] = []
        
        print("🔄 Syncing \(queue.count) pending reports...")
        
        for report in queue {
            do {
                try await network.uploadReport(report)
                syncedReports.append(report.id)
                print("✅ Synced report: \(report.id)")
            } catch let error as URLError where error.code == .cannotConnectToHost {
                print("⚠️ Server unreachable. Will retry later.")
            } catch {
                print("❌ Failed to sync report \(report.id): \(error)")
            }
        }
        
        // Remove successfully synced reports from queue
        if !syncedReports.isEmpty {
            queue.removeAll { syncedReports.contains($0.id) }
            savePendingReports(queue)
            
            let remainingCount = queue.count
            await MainActor.run {
                self.pendingUploads = remainingCount
            }
            
            print("✅ Synced \(syncedReports.count) reports")
        }
        
        // 2. Fetch remote reports
        await fetchReports()
        
        await MainActor.run {
            self.lastSyncDate = Date()
            self.isSyncing = false
        }
    }
    
    func fetchReports() async {
        do {
            print("📥 Fetching remote reports...")
            let reports = try await network.fetchReports()
            await MainActor.run {
                ReportStore.shared.merge(newReports: reports)
            }
            print("✅ Fetched \(reports.count) reports")
        } catch {
            print("❌ Failed to fetch reports: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func getPendingReports() -> [StoredReport] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let reports = try? JSONDecoder().decode([StoredReport].self, from: data) else {
            return []
        }
        return reports
    }
    
    private func savePendingReports(_ reports: [StoredReport]) {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }
}
