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
        
        for report in newReports {
            if !reports.contains(where: { $0.id == report.id }) {
                reports.append(report)
                updated = true
            }
        }
        
        if updated {
            reports.sort { $0.date > $1.date }
            persist()
        }
    }
}
