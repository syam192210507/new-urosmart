import Foundation
import UIKit

final class ReportStore: ObservableObject {
    static let shared = ReportStore()

    @Published private(set) var reports: [StoredReport] = []

    private let fileManager = FileManager.default
    private let metadataFileName = "reports.json"

    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var reportsDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("UroSmartReports")
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    private var metadataURL: URL {
        reportsDirectory.appendingPathComponent(metadataFileName)
    }

    func load() {
        do {
            let data = try Data(contentsOf: metadataURL)
            let decoded = try JSONDecoder().decode([StoredReport].self, from: data)
            self.reports = decoded.sorted { $0.date > $1.date }
        } catch {
            self.reports = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(reports)
            try data.write(to: metadataURL)
        } catch {
            print("Failed to persist reports: \(error)")
        }
    }

    func add(report: StoredReport) {
        reports.insert(report, at: 0)
        persist()
    }
    
    func merge(newReports: [StoredReport]) {
        var updated = false
        
        for newReport in newReports {
            // Check if report already exists by ID
            if reports.contains(where: { $0.id == newReport.id }) {
                continue // Skip - already have this report with same ID
            }
            
            // Check if report is a duplicate based on case number and date
            // (Local reports may have UUID IDs while backend returns integer IDs)
            let isDuplicate = reports.contains { existingReport in
                // Match by case number and date within 5 seconds
                existingReport.caseNumber == newReport.caseNumber &&
                abs(existingReport.date.timeIntervalSince(newReport.date)) < 5.0
            }
            
            if isDuplicate {
                // Replace the old local version with the backend version
                // This ensures we use the canonical backend ID
                if let index = reports.firstIndex(where: { 
                    $0.caseNumber == newReport.caseNumber &&
                    abs($0.date.timeIntervalSince(newReport.date)) < 5.0
                }) {
                    reports[index] = newReport
                    updated = true
                }
            } else {
                // Genuinely new report - add it
                reports.append(newReport)
                updated = true
            }
        }
        
        if updated {
            reports.sort { $0.date > $1.date }
            persist()
        }
    }
    
    // MARK: - ID Update
    
    /// Update a report's ID (used after syncing to backend to replace local UUID with backend ID)
    func updateReportId(oldId: String, newId: String) {
        if let index = reports.firstIndex(where: { $0.id == oldId }) {
            var updatedReport = reports[index]
            updatedReport.id = newId
            reports[index] = updatedReport
            persist()
        }
    }
    
    /// Check if a case number already exists
    func caseNumberExists(_ caseNumber: String) -> Bool {
        return reports.contains { $0.caseNumber.caseInsensitiveCompare(caseNumber) == .orderedSame }
    }
    
    // MARK: - User Session Management
    
    /// Clear all reports when user logs out
    /// This ensures reports from different accounts don't mix
    func clear() {
        reports = []
        // Remove the metadata file
        try? FileManager.default.removeItem(at: metadataURL)
        // Optionally remove all report PDFs
        try? FileManager.default.removeItem(at: reportsDirectory)
        // Recreate empty directory
        try? FileManager.default.createDirectory(at: reportsDirectory, withIntermediateDirectories: true)
        print("✅ ReportStore cleared for user logout")
    }
}
