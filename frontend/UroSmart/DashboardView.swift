import SwiftUI

struct DashboardView: View {
    @State private var showingScanSubmission = false
    @State private var showingReports = false
    @State private var showingLogoutAlert = false
    @State private var showSidebar = false
    @State private var showProfile = false
    @Binding var isLoggedIn: Bool
    
    // Responsive sizing
    private var isSmallDevice: Bool { DeviceType.current.isSmallDevice }
    private var titleFontSize: CGFloat { isSmallDevice ? 36 : 48 }
    private var subtitleFontSize: CGFloat { isSmallDevice ? 20 : 24 }
    private var horizontalPadding: CGFloat { ResponsiveSize.shared.horizontalPadding }
    
    var body: some View {
        GeometryReader { geometry in
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
                
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection(width: geometry.size.width)
                        actionButtons
                    }
                }
                
                // Sidebar
                SidebarView(isOpen: $showSidebar, showProfile: $showProfile)
                    .ignoresSafeArea()
            }
        }
        .navigationBarHidden(true)
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) { performLogout() }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .fullScreenCover(isPresented: $showingScanSubmission) {
            ScanSubmissionView(isPresented: $showingScanSubmission)
                .interactiveDismissDisabled(true)
        }
        .fullScreenCover(isPresented: $showingReports) {
            MedicalReportsView(isPresented: $showingReports)
                .interactiveDismissDisabled(true)
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView(isPresented: $showProfile, isLoggedIn: $isLoggedIn)
                .interactiveDismissDisabled(true)
        }
        .onAppear {
            _ = FederatedLearningManager.shared
        }
        .task {
            // Try to sync user if created offline
            await AuthService.shared.syncUser()
        }
        .onChange(of: ConnectivityMonitor.shared.isOnline) { _, isOnline in
            if isOnline {
                Task {
                    // Sync user first (if offline-created)
                    await AuthService.shared.syncUser()
                    // Then sync any pending reports
                    await ReportSyncService.shared.syncNow()
                }
            }
        }
    }
    
    // MARK: - Header UI
    private func headerSection(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            // White background container for the top part
            VStack(spacing: 0) {
                // Top Row: Menu and Logout Buttons
                HStack {
                    Button(action: {
                        withAnimation {
                            showSidebar = true
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.system(size: isSmallDevice ? 20 : 24))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingLogoutAlert = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: isSmallDevice ? 9 : 10))
                            Text("Logout")
                                .font(.system(size: isSmallDevice ? 10 : 11))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.red, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, isSmallDevice ? 12 : 20)
                
                // Title Section (Pushed down)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome To The")
                            .font(.system(size: subtitleFontSize, weight: .medium))
                            .foregroundColor(.black)
                            .minimumScaleFactor(0.8)
                        
                        Text("UROSMART")
                            .font(.system(size: titleFontSize, weight: .bold))
                            .foregroundColor(.black)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, isSmallDevice ? 20 : 30)
                .padding(.bottom, isSmallDevice ? 20 : 30)
            }
            .background(Color.white)
            
            // Curve - now uses dynamic width from GeometryReader
            CurvedShape()
                .fill(Color.white)
                .frame(width: width, height: 40)
        }
    }
    
    // MARK: - Buttons Section
    private var actionButtons: some View {
        let cardSpacing: CGFloat = isSmallDevice ? 20 : 25
        let cardPadding: CGFloat = isSmallDevice ? 16 : 20
        
        return VStack(spacing: cardSpacing) {
            
            // UPLOAD BUTTON
            Button(action: { showingScanSubmission = true }) {
                uploadCard
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, cardPadding)
            
            // REPORTS BUTTON
            Button(action: { showingReports = true }) {
                reportsCard
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, cardPadding)
            
        }
        .padding(.top, isSmallDevice ? 20 : 30)
        .padding(.bottom, isSmallDevice ? 30 : 50)
    }
    
    // MARK: - Upload Card
    private var uploadCard: some View {
        let iconSize: CGFloat = isSmallDevice ? 60 : 80
        let iconFontSize: CGFloat = isSmallDevice ? 30 : 40
        
        return VStack(spacing: isSmallDevice ? 16 : 20) {
            ZStack {
                RoundedRectangle(cornerRadius: isSmallDevice ? 16 : 20)
                    .fill(Color(red: 0.35, green: 0.55, blue: 1.0))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "viewfinder")
                    .font(.system(size: iconFontSize, weight: .light))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text("Upload medical scans for analysis")
                    .font(.system(size: isSmallDevice ? 14 : 15, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.9)
                
                Text("Submit 2 images for processing")
                    .font(.system(size: isSmallDevice ? 11 : 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, isSmallDevice ? 24 : 30)
        .padding(.vertical, isSmallDevice ? 28 : 35)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(ResponsiveSize.shared.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Reports Card
    private var reportsCard: some View {
        let iconSize: CGFloat = isSmallDevice ? 60 : 80
        let iconFontSize: CGFloat = isSmallDevice ? 30 : 40
        
        return VStack(spacing: isSmallDevice ? 16 : 20) {
            ZStack {
                RoundedRectangle(cornerRadius: isSmallDevice ? 16 : 20)
                    .fill(Color(red: 0.2, green: 0.65, blue: 0.35))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: iconFontSize))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text("View and download patient reports")
                    .font(.system(size: isSmallDevice ? 14 : 15, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.9)
                
                Text("Access all medical reports")
                    .font(.system(size: isSmallDevice ? 11 : 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, isSmallDevice ? 24 : 30)
        .padding(.vertical, isSmallDevice ? 28 : 35)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(ResponsiveSize.shared.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Logout Logic
    private func performLogout() {
        // Stop federated learning service
        if AppConfig.enableFederatedLearning {
            FederatedBackgroundService.shared.stop()
        }
        
        // Clear all user data and reports
        Task {
            await AuthService.shared.logout()
        }
        
        UserDefaults.standard.set(false, forKey: "isLoggedIn") // IMPORTANT
        withAnimation(.easeInOut(duration: 0.5)) {
            isLoggedIn = false
        }
    }
}

// MARK: - Curved Shape for Header
struct CurvedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height),
            control: CGPoint(x: width/2, y: height + 25)
        )
        path.closeSubpath()
        
        return path
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DashboardView(isLoggedIn: .constant(true))
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("iPhone SE")
            
            DashboardView(isLoggedIn: .constant(true))
                .previewDevice("iPhone 14")
                .previewDisplayName("iPhone 14")
            
            DashboardView(isLoggedIn: .constant(true))
                .previewDevice("iPhone 14 Pro Max")
                .previewDisplayName("iPhone 14 Pro Max")
        }
    }
}

