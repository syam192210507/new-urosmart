import SwiftUI

struct ScanSubmissionView: View {
    @State private var caseNumber: String = ""
    @State private var firstImage: UIImage?
    @State private var secondImage: UIImage?
    @State private var showingImagePicker = false
    @State private var activeImagePicker: ImagePickerType?
    @Binding var isPresented: Bool
    @State private var isProcessing: Bool = false
    @State private var alertMessage: String?
    @State private var showReportPreview: Bool = false
    @State private var generatedReport: StoredReport?
    @State private var showDetectionsSheet: Bool = false
    @State private var detectionImage: UIImage?
    @State private var detectionAnalysis: AnalysisResult?
    
    enum ImagePickerType {
        case first, second
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                    
                    // MARK: - Header
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
                    
                    // MARK: - Main Card
                    VStack(spacing: 0) {
                        
                        // MARK: - Title
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                                
                                Text("New Scan Submission")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                Spacer()
                            }
                            
                            Text("Upload two medical scans for analysis. Ensure images are clear and properly oriented.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // MARK: - Case Number
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Case No.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Text("*")
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                            }
                            
                            TextField("Input case no. for easy identification", text: $caseNumber)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .font(.system(size: 14))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        
                        // MARK: - Image Pickers
                        VStack(spacing: 20) {
                            
                            // FIRST IMAGE
                            imagePickerSection(
                                title: "First Medical Image",
                                image: $firstImage,
                                pickerType: .first
                            )
                            
                            // SECOND IMAGE
                            imagePickerSection(
                                title: "Second Medical Image",
                                image: $secondImage,
                                pickerType: .second
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        
                        // MARK: - Buttons
                        HStack(spacing: 12) {
                            Button(action: submitScan) {
                                Text("Submit Scan")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(isProcessing ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(isProcessing)
                            
                            Button(action: { isPresented = false }) {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.clear)
                                    .foregroundColor(.gray)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        
        // MARK: - Image Picker Sheet
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: activeImagePicker == .first ? $firstImage : $secondImage)
        }
        .sheet(isPresented: $showDetectionsSheet) {
            DetectionsView(
                image: detectionImage,
                analysis: detectionAnalysis,
                isPresented: $showDetectionsSheet
            )
        }
        
        // MARK: - Loading Overlay
        .overlay(
            Group {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Analyzing...")
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                }
            }
        )
        
        // MARK: - Alerts
        .alert(item: Binding(get: {
            alertMessage.map { SubmissionAlertItem(message: $0) }
        }, set: { newValue in
            alertMessage = newValue?.message
        })) { item in
            Alert(title: Text("Submission"), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
        
        // MARK: - PDF Preview
        .fullScreenCover(isPresented: $showReportPreview) {
            if let report = generatedReport {
                ReportPreviewView(report: report, isPresented: $showReportPreview)
            }
        }
    }
}

private struct SubmissionAlertItem: Identifiable {
    let id = UUID()
    let message: String
}

extension ScanSubmissionView {
    
    // MARK: - Image Picker Section Builder
    private func imagePickerSection(title: String, image: Binding<UIImage?>, pickerType: ImagePickerType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            Button(action: {
                activeImagePicker = pickerType
                showingImagePicker = true
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .frame(height: 120)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    if let selectedImage = image.wrappedValue {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            
                            Text("Drop image here or click to browse")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

//
// MARK: - Processing Logic
//
extension ScanSubmissionView {
    
    private func showDetections(image: UIImage, analysis: AnalysisResult) {
        self.detectionImage = image
        self.detectionAnalysis = analysis
        self.showDetectionsSheet = true
    }

    private func submitScan() {
        guard !caseNumber.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Please enter a Case No."
            return
        }
        guard let img1 = firstImage ?? secondImage else {
            alertMessage = "Please select at least one image."
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                print("🔬 Starting image analysis...")
                let analyzer = ImageAnalyzer()
                
                // Analyze image (Online -> Offline fallback)
                let analysis = await analyzer.analyzeAsync(img1)
                
                // Generate PDF
                let reportId = UUID().uuidString
                let pdfName = "\(reportId).pdf"
                let imageName = "\(reportId).jpg"
                let saveURL = ReportStore.shared.reportsDirectory.appendingPathComponent(pdfName)
                let imageSaveURL = ReportStore.shared.reportsDirectory.appendingPathComponent(imageName)
                
                // Save image for bounding box display
                if let data = img1.jpegData(compressionQuality: 0.8) {
                    try? data.write(to: imageSaveURL)
                }
                
                let generator = PDFReportGenerator()
                var imgs: [UIImage] = []
                if let i1 = firstImage { imgs.append(i1) }
                if let i2 = secondImage { imgs.append(i2) }
                
                try generator.generate(
                    caseNumber: caseNumber,
                    date: Date(),
                    images: imgs,
                    analysis: analysis,
                    saveURL: saveURL
                )
                
                let stored = StoredReport(
                    id: reportId,
                    caseNumber: caseNumber,
                    date: Date(),
                    analysis: analysis,
                    pdfFileName: pdfName,
                    imageFileName: imageName
                )
                
                await MainActor.run {
                    // Save locally ONLY
                    ReportStore.shared.add(report: stored)
                    
                    // Queue for backend sync
                    ReportSyncService.shared.queueReport(stored)
                    
                    print("✅ Report generated and saved: \(stored.pdfFileName)")
                    
                    isProcessing = false
                    
                    generatedReport = stored
                    showReportPreview = true
                }
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Failed to generate report: \(error.localizedDescription)"
                }
            }
        }
    }
}

//
// MARK: - Image Picker
//
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ScanSubmissionView_Previews: PreviewProvider {
    static var previews: some View {
        ScanSubmissionView(isPresented: .constant(true))
    }
}
