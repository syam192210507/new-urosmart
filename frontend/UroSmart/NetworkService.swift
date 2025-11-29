import Foundation

/// Backend API service for authentication and reports
actor NetworkService {
    static let shared = NetworkService()
    
    // Configure your backend URL here
    private let baseURL = AppConfig.apiBaseURL
    
    private let connectivity = ConnectivityMonitor.shared
    private let keychain = KeychainHelper.shared
    
    private init() {}
    
    // MARK: - Authentication
    
    func signup(phoneNumber: String, email: String, password: String) async throws -> User {
        guard connectivity.isOnline else {
            throw NetworkError.offline
        }
        
        let url = URL(string: "\(baseURL)/auth/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "phone_number": phoneNumber,
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        // Save access token to keychain
        _ = keychain.save(authResponse.access_token, forKey: KeychainHelper.Key.accessToken)
        
        return authResponse.user
    }
    
    func login(email: String, password: String) async throws -> User {
        guard connectivity.isOnline else {
            throw NetworkError.offline
        }
        
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        // Save access token to keychain
        _ = keychain.save(authResponse.access_token, forKey: KeychainHelper.Key.accessToken)
        
        return authResponse.user
    }
    
    func forgotPassword(phoneNumber: String) async throws -> String {
        guard connectivity.isOnline else {
            throw NetworkError.offline
        }
        
        let url = URL(string: "\(baseURL)/auth/forgot-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["phone_number": phoneNumber]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        // For dev, we might get an OTP back. In prod, just a message.
        struct ForgotResponse: Codable {
            let message: String
            let dev_otp: String?
        }
        
        let result = try JSONDecoder().decode(ForgotResponse.self, from: data)
        return result.dev_otp ?? result.message
    }
    
    func resetPassword(phoneNumber: String, otp: String, newPassword: String) async throws {
        guard connectivity.isOnline else {
            throw NetworkError.offline
        }
        
        let url = URL(string: "\(baseURL)/auth/reset-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "phone_number": phoneNumber,
            "otp": otp,
            "new_password": newPassword
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
    
    // MARK: - Reports
    
    func uploadReport(_ report: StoredReport) async throws {
        guard connectivity.isOnline else {
            throw NetworkError.offline
        }
        
        let url = URL(string: "\(baseURL)/reports")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available (optional for development)
        if let token = keychain.get(forKey: KeychainHelper.Key.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Transform to backend format
        let backendReport: [String: Any] = [
            "case_number": report.caseNumber,
            "yeast_present": report.analysis.yeast.present,
            "yeast_count": report.analysis.yeast.present ? 1 : 0,
            "yeast_confidence": report.analysis.yeast.confidence,
            "triple_phosphate_present": report.analysis.triplePhosphate.present,
            "triple_phosphate_count": report.analysis.triplePhosphate.present ? 1 : 0,
            "triple_phosphate_confidence": report.analysis.triplePhosphate.confidence,
            "calcium_oxalate_present": report.analysis.calciumOxalate.present,
            "calcium_oxalate_count": report.analysis.calciumOxalate.present ? 1 : 0,
            "calcium_oxalate_confidence": report.analysis.calciumOxalate.confidence,
            "squamous_cells_present": report.analysis.squamousCells.present,
            "squamous_cells_count": report.analysis.squamousCells.present ? 1 : 0,
            "squamous_cells_confidence": report.analysis.squamousCells.confidence,
            "uric_acid_present": report.analysis.uricAcid.present,
            "uric_acid_count": report.analysis.uricAcid.present ? 1 : 0,
            "uric_acid_confidence": report.analysis.uricAcid.confidence
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: backendReport)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
    
    func fetchReports() async throws -> [StoredReport] {
        guard connectivity.isOnline else {
            throw NetworkError.offline
        }
        
        // Get access token from keychain
        guard let token = keychain.get(forKey: KeychainHelper.Key.accessToken) else {
            throw NetworkError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/reports")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        // Decode backend response
        struct BackendReportResponse: Decodable {
            let reports: [BackendReport]
        }
        
        struct BackendReport: Decodable {
            let id: Int
            let case_number: String
            let report_date: String
            let results: BackendAnalysisResults
            let pdf_path: String?
            let image_paths: String? // JSON string
        }
        
        struct BackendAnalysisResults: Decodable {
            let yeast: BackendDetection
            let triple_phosphate: BackendDetection
            let calcium_oxalate: BackendDetection
            let squamous_cells: BackendDetection
            let uric_acid: BackendDetection
        }
        
        struct BackendDetection: Decodable {
            let present: Bool
            let confidence: Double
        }
        
        let decodedResponse = try JSONDecoder().decode(BackendReportResponse.self, from: data)
        
        // Map to StoredReport
        return decodedResponse.reports.map { backendReport in
            // Parse date
            let date = ISO8601DateFormatter().date(from: backendReport.report_date) ?? Date()
            
            // Map analysis results
            let analysis = AnalysisResult(
                yeast: ObjectDetection(name: "Yeast", present: backendReport.results.yeast.present, confidence: backendReport.results.yeast.confidence),
                triplePhosphate: ObjectDetection(name: "Triple Phosphate", present: backendReport.results.triple_phosphate.present, confidence: backendReport.results.triple_phosphate.confidence),
                calciumOxalate: ObjectDetection(name: "Calcium Oxalate", present: backendReport.results.calcium_oxalate.present, confidence: backendReport.results.calcium_oxalate.confidence),
                squamousCells: ObjectDetection(name: "Squamous Cells", present: backendReport.results.squamous_cells.present, confidence: backendReport.results.squamous_cells.confidence),
                uricAcid: ObjectDetection(name: "Uric Acid", present: backendReport.results.uric_acid.present, confidence: backendReport.results.uric_acid.confidence)
            )
            
            return StoredReport(
                id: String(backendReport.id),
                caseNumber: backendReport.case_number,
                date: date,
                analysis: analysis,
                pdfFileName: backendReport.pdf_path ?? "",
                imageFileName: nil // We don't download images automatically yet
            )
        }
    }
    
    func downloadReportPDF(reportId: String) async throws -> URL {
        guard connectivity.isOnline else {
            throw NetworkError.offline
        }
        
        guard let token = keychain.get(forKey: KeychainHelper.Key.accessToken) else {
            throw NetworkError.unauthorized
        }
        
        // We need the filename, which is stored in the report object.
        // But here we might just want to download by ID or filename.
        // The backend endpoint is /api/files/reports/<filename>
        // So we need the filename.
        
        // Let's assume the caller passes the filename, or we fetch the report first.
        // For now, let's assume the reportId IS the filename or we can get it.
        // Actually, looking at StoredReport, pdfFileName is stored.
        
        let url = URL(string: "\(baseURL)/files/reports/\(reportId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (localURL, response) = try await URLSession.shared.download(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        // Move to documents directory
        let destinationURL = ReportStore.shared.reportsDirectory.appendingPathComponent(reportId)
        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.moveItem(at: localURL, to: destinationURL)
        
        return destinationURL
    }
}

// MARK: - Models

struct AuthResponse: Codable {
    let user: User
    let access_token: String
}

// MARK: - Errors

enum NetworkError: LocalizedError {
    case offline
    case invalidResponse
    case serverError(String)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unauthorized:
            return "Please login to continue"
        }
    }
}
