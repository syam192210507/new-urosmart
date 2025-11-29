import SwiftUI

struct MedicalReportsView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @ObservedObject private var store = ReportStore.shared
    @ObservedObject private var syncService = ReportSyncService.shared
    @ObservedObject private var connectivity = ConnectivityMonitor.shared
    @State private var isFilteringByDate = true
    @State private var alertMessage: String?
    @State private var selectedReport: StoredReport?
    @State private var showingPreview = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.25, green: 0.45, blue: 1.0),
                        Color(red: 0.0, green: 0.75, blue: 0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            isPresented = false
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 16))
                                Text("Back to Dashboard")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Title with sync status
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Medical Reports")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Sync status indicator
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(connectivity.isOnline ? Color.green : Color.gray)
                                    .frame(width: 8, height: 8)
                                
                                if syncService.isSyncing {
                                    Text("Syncing...")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.white)
                                } else if connectivity.isOnline {
                                    if let lastSync = syncService.lastSyncDate {
                                        Text("Synced \(timeAgo(lastSync))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.9))
                                    } else {
                                        Text("Online")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                } else {
                                    Text("Offline")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    if syncService.pendingUploads > 0 {
                                        Text("• \(syncService.pendingUploads) pending")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Manual sync button
                        if connectivity.isOnline && !syncService.isSyncing {
                            Button(action: {
                                Task {
                                    await syncService.syncNow()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Main content card
                    VStack(spacing: 0) {
                        VStack(spacing: 16) {
                            // Search bar with calendar - Unified tap area
                            Button(action: {
                                showingDatePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        Text("Search for patient name or ID")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    
                                    Image(systemName: "calendar")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Selected date display
                            if isFilteringByDate {
                                HStack {
                                    Text("Reports for: \(formattedDate)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.blue)
                                    
                                    Spacer()
                                    
                                    Button("Clear Filter") {
                                        isFilteringByDate = false
                                        selectedDate = Date()
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                }
                                .padding(.horizontal, 4)
                            } else {
                                HStack {
                                    Text("All Reports")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                        
                        // Reports section
                        VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Medical Reports (\(filteredReports.count))")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                if filteredReports.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray.opacity(0.5))
                                        
                                        Text("No reports found for selected date")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    ScrollView {
                                        LazyVStack(spacing: 12) {
                                            ForEach(filteredReports) { report in
                                                ReportRowView(report: report)                                                .onTapGesture {
                                                    selectedReport = report
                                                    showingPreview = true
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 20)
                                    }
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal, 16)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $selectedDate, onDateSelected: {
                    isFilteringByDate = true
                }, onShowAll: {
                    isFilteringByDate = false
                })
            }
            .alert(item: Binding(get: {
                alertMessage.map { MedicalReportAlertItem(message: $0) }
            }, set: { newValue in
                alertMessage = newValue?.message
            })) { item in
                Alert(title: Text("Error"), message: Text(item.message), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(isPresented: $showingPreview) {
                if let report = selectedReport {
                    ReportPreviewView(report: report, isPresented: $showingPreview)
                }
            }
            .onAppear {
                store.load()
                Task {
                    await syncService.fetchReports()
                }
            }
        }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    private var filteredReports: [StoredReport] {
        let calendar = Calendar.current
        
        // Start with all reports
        var result = store.reports
        
        // Filter by date if enabled
        if isFilteringByDate {
            result = result.filter { report in
                calendar.isDate(report.date, inSameDayAs: selectedDate)
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { report in
                report.caseNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }
}

private struct MedicalReportAlertItem: Identifiable {
    let id = UUID()
    let message: String
}

// Report row component
struct ReportRowView: View {
    let report: StoredReport
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(report.caseNumber)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                // Show detected objects
                let detectedObjects = [
                    report.analysis.yeast.present ? "Yeast" : nil,
                    report.analysis.triplePhosphate.present ? "Triple Phosphate" : nil,
                    report.analysis.calciumOxalate.present ? "Calcium Oxalate" : nil,
                    report.analysis.squamousCells.present ? "Squamous Cells" : nil,
                    report.analysis.uricAcid.present ? "Uric Acid" : nil
                ].compactMap { $0 }
                
                if detectedObjects.isEmpty {
                    Text("No objects detected")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                } else {
                    Text("Detected: \(detectedObjects.joined(separator: ", "))")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if FileManager.default.fileExists(atPath: report.pdfURL.path) {
                ShareLink(item: report.pdfURL) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 14))
                        Text("Download Report")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
            } else {
                Button(action: {
                    Task {
                        do {
                            _ = try await NetworkService.shared.downloadReportPDF(reportId: report.pdfFileName)
                            // Reload store to update UI
                            await MainActor.run {
                                ReportStore.shared.load()
                            }
                        } catch {
                            print("Failed to download PDF: \(error)")
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 14))
                        Text("Download PDF")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Date picker modal
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    let onDateSelected: () -> Void
    let onShowAll: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Button(action: {
                    onShowAll()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Show All Reports")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDateSelected()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct MedicalReportsView_Previews: PreviewProvider {
    static var previews: some View {
        MedicalReportsView(isPresented: .constant(true))
    }
}
