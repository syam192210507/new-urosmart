import Foundation
import UIKit

struct StoredReport: Identifiable, Codable {
    let id: String
    let caseNumber: String
    let date: Date
    let analysis: AnalysisResult
    let pdfFileName: String
    let imageFileName: String? // Path to saved analysis image
}

extension StoredReport {
    var pdfURL: URL {
        ReportStore.shared.reportsDirectory.appendingPathComponent(pdfFileName)
    }
    
    var imageURL: URL? {
        guard let fileName = imageFileName else { return nil }
        return ReportStore.shared.reportsDirectory.appendingPathComponent(fileName)
    }
}
