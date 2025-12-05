import SwiftUI

struct GetStartedView: View {
    @Binding var showLogin: Bool
    
    // Responsive sizing
    private var isSmallDevice: Bool { DeviceType.current.isSmallDevice }
    private var iconSize: CGFloat { isSmallDevice ? 90 : 120 }
    private var titleSize: CGFloat { isSmallDevice ? 26 : 32 }
    private var subtitleSize: CGFloat { isSmallDevice ? 15 : 18 }
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.4, blue: 1.0),
                    Color(red: 0.0, green: 0.8, blue: 0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: isSmallDevice ? 24 : 30) {
                Spacer()
                
                // App Icon / Logo
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: iconSize, height: iconSize)
                    
                    Image(systemName: "stethoscope")
                        .font(.system(size: isSmallDevice ? 45 : 60))
                        .foregroundColor(.white)
                }
                .padding(.bottom, isSmallDevice ? 16 : 20)
                
                // Title and Description
                VStack(spacing: isSmallDevice ? 12 : 16) {
                    Text("Welcome to UroSmart")
                        .font(.system(size: titleSize, weight: .bold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text("Advanced Urinalysis Analysis\nat Your Fingertips")
                        .font(.system(size: subtitleSize))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, isSmallDevice ? 30 : 40)
                        .minimumScaleFactor(0.85)
                }
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    withAnimation {
                        showLogin = true
                    }
                }) {
                    Text("Get Started")
                        .font(.system(size: isSmallDevice ? 16 : 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 1.0))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isSmallDevice ? 14 : 16)
                        .background(Color.white)
                        .cornerRadius(ResponsiveSize.shared.cardCornerRadius)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, isSmallDevice ? 30 : 40)
                .padding(.bottom, isSmallDevice ? 40 : 50)
            }
        }
    }
}

struct GetStartedView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GetStartedView(showLogin: .constant(false))
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("iPhone SE")
            
            GetStartedView(showLogin: .constant(false))
                .previewDevice("iPhone 14 Pro Max")
                .previewDisplayName("iPhone 14 Pro Max")
        }
    }
}

