import SwiftUI
import PDFKit

struct ReportPreviewView: View {
    let report: StoredReport
    @Binding var isPresented: Bool
    @State private var pdfURL: URL?
    @State private var isDownloading = false
    @State private var alertMessage: String?
    
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
                                Image(systemName: "xmark")
                                    .font(.system(size: 16))
                                Text("Close")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        Text("Report Generated")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        Color.clear
                            .frame(width: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 0) // Reduced from 10
                    .padding(.bottom, 8) // Reduced from 16
                    
                    // Main content card
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: 20) {
                                // Success icon
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                    .padding(.top, 20)
                                
                                Text("Report Successfully Generated!")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                
                                // Report details card
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(.blue)
                                        Text("Report Details")
                                            .font(.system(size: 16, weight: .semibold))
                                        Spacer()
                                    }
                                    
                                    Divider()
                                    
                                    // Image with Bounding Boxes
                                    if let imageURL = report.imageURL,
                                       let imageData = try? Data(contentsOf: imageURL),
                                       let uiImage = UIImage(data: imageData) {
                                        
                                        ZStack {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .cornerRadius(8)
                                            
                                            // Bounding Box Overlay
                                            BoundingBoxOverlay(analysis: report.analysis, imageSize: uiImage.size)
                                        }
                                        .frame(height: 200)
                                        .cornerRadius(8)
                                        .padding(.bottom, 8)
                                    }
                                    
                                    // Case number
                                    HStack {
                                        Text("Case No:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(report.caseNumber)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    
                                    // Date
                                    HStack {
                                        Text("Date:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(report.date, style: .date)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    
                                    // Detection status
                                    HStack {
                                        Text("Status:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(report.analysis.present ? "Objects Detected" : "No Objects Detected")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(report.analysis.present ? .red : .green)
                                    }
                                }
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                // Detection results
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "chart.bar.fill")
                                            .foregroundColor(.purple)
                                        Text("Detection Results")
                                            .font(.system(size: 16, weight: .semibold))
                                        Spacer()
                                    }
                                    
                                    Divider()
                                    
                                    DetectionRow(
                                        name: "Yeast",
                                        detection: report.analysis.yeast,
                                        icon: "circle.fill",
                                        color: .orange
                                    )
                                    
                                    DetectionRow(
                                        name: "Triple Phosphate",
                                        detection: report.analysis.triplePhosphate,
                                        icon: "triangle.fill",
                                        color: .blue
                                    )
                                    
                                    DetectionRow(
                                        name: "Calcium Oxalate",
                                        detection: report.analysis.calciumOxalate,
                                        icon: "diamond.fill",
                                        color: .red
                                    )
                                    
                                    DetectionRow(
                                        name: "Squamous Cells",
                                        detection: report.analysis.squamousCells,
                                        icon: "square.fill",
                                        color: .green
                                    )
                                    
                                    DetectionRow(
                                        name: "Uric Acid",
                                        detection: report.analysis.uricAcid,
                                        icon: "hexagon.fill",
                                        color: .purple
                                    )
                                }
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                // Action buttons
                                VStack(spacing: 12) {
                                    // Download button
                                    // MARK: - Action Buttons
                                    HStack(spacing: 12) {
                                        let pdfPath = ReportStore.shared.reportsDirectory.appendingPathComponent(report.pdfFileName)
                                        
                                        if FileManager.default.fileExists(atPath: pdfPath.path) {
                                            ShareLink(item: pdfPath) {
                                                HStack {
                                                    Image(systemName: "arrow.down.circle")
                                                    Text("Download PDF")
                                                }
                                                .font(.system(size: 16, weight: .medium))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                            }
                                            
                                            ShareLink(item: pdfPath) {
                                                HStack {
                                                    Image(systemName: "square.and.arrow.up")
                                                    Text("Share")
                                                }
                                                .font(.system(size: 16, weight: .medium))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                                .background(Color(.systemGray6))
                                                .foregroundColor(.blue)
                                                .cornerRadius(12)
                                            }
                                        } else {
                                            Text("PDF File Missing")
                                                .foregroundColor(.gray)
                                                .padding()
                                        }
                                    }
                                    .padding(.top, 10)
                                    
                                    Button(action: {
                                        isPresented = false
                                    }) {
                                        Text("View All Reports")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .underline()
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                }
            }
            // Loading overlay for download
            if isDownloading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("Preparing PDF...")
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 10)
            }
        }
        .navigationBarHidden(true)
        .alert(item: Binding(get: {
            alertMessage.map { PreviewAlertItem(message: $0) }
        }, set: { newValue in
            alertMessage = newValue?.message
        })) { item in
            Alert(title: Text("Error"), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
    }
    
}

private struct PreviewAlertItem: Identifiable {
    let id = UUID()
    let message: String
}

// Detection row component
struct DetectionRow: View {
    let name: String
    let detection: ObjectDetection
    let icon: String
    let color: Color
    
    var confidencePercentage: String {
        String(format: "%.0f%%", detection.confidence * 100)
    }
    
    var confidenceColor: Color {
        if detection.confidence >= 0.7 {
            return .green
        } else if detection.confidence >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                
                HStack(spacing: 6) {
                    Text(detection.present ? "Detected" : "Not detected")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    // Confidence level badge
                    Text(confidencePercentage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(confidenceColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(confidenceColor.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Status badge
            Text(detection.present ? "Present" : "Absent")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(detection.present ? Color.red : Color.green)
                .cornerRadius(12)
        }
    }
}

// Corner radius extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct BoundingBoxOverlay: View {
    let analysis: AnalysisResult
    let imageSize: CGSize
    
    
    var body: some View {
        GeometryReader { geometry in
            let params = calculateDisplayParams(viewSize: geometry.size)
            
            ZStack {
                drawBoxes(for: analysis.yeast, color: .orange, params: params)
                drawBoxes(for: analysis.triplePhosphate, color: .blue, params: params)
                drawBoxes(for: analysis.calciumOxalate, color: .red, params: params)
                drawBoxes(for: analysis.squamousCells, color: .green, params: params)
                drawBoxes(for: analysis.uricAcid, color: .purple, params: params)
            }
        }
    }
    
    private struct DisplayParams {
        let size: CGSize
        let offset: CGPoint
    }
    
    private func calculateDisplayParams(viewSize: CGSize) -> DisplayParams {
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height
        
        if imageAspect > viewAspect {
            // Image is wider - fit to width
            let displayedSize = CGSize(
                width: viewSize.width,
                height: viewSize.width / imageAspect
            )
            let offset = CGPoint(
                x: 0,
                y: (viewSize.height - displayedSize.height) / 2
            )
            return DisplayParams(size: displayedSize, offset: offset)
        } else {
            // Image is taller - fit to height
            let displayedSize = CGSize(
                width: viewSize.height * imageAspect,
                height: viewSize.height
            )
            let offset = CGPoint(
                x: (viewSize.width - displayedSize.width) / 2,
                y: 0
            )
            return DisplayParams(size: displayedSize, offset: offset)
        }
    }
    
    // Helper to draw boxes for a detection type
    private func drawBoxes(for detection: ObjectDetection, color: Color, params: DisplayParams) -> some View {
        ForEach(0..<(detection.boundingBoxes?.count ?? 0), id: \.self) { index in
            if let box = detection.boundingBoxes?[index], box.count == 4 {
                // Coordinates are normalized (0-1), multiply by display size and add offset
                let x = CGFloat(box[0]) * params.size.width + params.offset.x
                let y = CGFloat(box[1]) * params.size.height + params.offset.y
                let w = CGFloat(box[2] - box[0]) * params.size.width
                let h = CGFloat(box[3] - box[1]) * params.size.height
                
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: w, height: h)
                        .position(x: x + w/2, y: y + h/2)
                    
                    Text("\(detection.name) \(Int(detection.confidence * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(2)
                        .background(color)
                        .cornerRadius(2)
                        .position(x: x + 30, y: y - 8)
                }
            }
        }
    }
}

struct ReportPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ReportPreviewView(
            report: StoredReport(
                id: "preview",
                caseNumber: "TEST-001",
                date: Date(),
                analysis: AnalysisResult(
                    yeast: ObjectDetection(name: "Yeast", present: true, confidence: 0.85),
                    triplePhosphate: ObjectDetection(name: "Triple Phosphate", present: false, confidence: 0.0),
                    calciumOxalate: ObjectDetection(name: "Calcium Oxalate", present: true, confidence: 0.72),
                    squamousCells: ObjectDetection(name: "Squamous Cells", present: true, confidence: 0.68),
                    uricAcid: ObjectDetection(name: "Uric Acid", present: false, confidence: 0.0)
                ),
                pdfFileName: "test.pdf",
                imageFileName: nil
            ),
            isPresented: .constant(true)
        )
    }
}
