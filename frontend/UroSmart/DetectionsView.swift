import SwiftUI

struct DetectionsView: View {
    let image: UIImage?
    let analysis: AnalysisResult?
    @Binding var isPresented: Bool
    
    var body: some View {
        if let img = image, let result = analysis {
            VStack {
                HStack {
                    Text("Detected Objects")
                        .font(.headline)
                    Spacer()
                    Button("Close") {
                        isPresented = false
                    }
                }
                .padding()
                
                ScrollView {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(
                            GeometryReader { geo in
                                BoundingBoxOverlay(analysis: result, imageSize: img.size)
                            }
                        )
                }
            }
        } else {
            Text("No detection data available")
                .padding()
        }
    }
}
