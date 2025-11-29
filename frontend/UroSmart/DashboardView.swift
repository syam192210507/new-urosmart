import SwiftUI

struct DashboardView: View {
    @State private var showingScanSubmission = false
    @State private var showingReports = false
    @State private var showingLogoutAlert = false
    @State private var showSidebar = false
    @Binding var isLoggedIn: Bool
    
    var body: some View {
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
                    headerSection
                    actionButtons
                }
            }
            
            // Sidebar
            SidebarView(isOpen: $showSidebar)
                .ignoresSafeArea()
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
        .onAppear {
            _ = FederatedLearningManager.shared
        }
    }
    
    // MARK: - Header UI
    private var headerSection: some View {
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
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingLogoutAlert = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 10))
                            Text("Logout")
                                .font(.system(size: 11))
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
                .padding(.horizontal, 24)
                .padding(.top, 20) // Space from top
                
                // Title Section (Pushed down)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome To The")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.black)
                        
                        Text("UROSMART")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 30) // Push text down
                .padding(.bottom, 30)
            }
            .background(Color.white)
            
            // Curve
            Path { path in
                let width = UIScreen.main.bounds.width
                let height: CGFloat = 40
                
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: width, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: 0, y: height),
                    control: CGPoint(x: width/2, y: height + 25)
                )
                path.closeSubpath()
            }
            .fill(Color.white)
            .frame(height: 40)
        }
    }
    
    // MARK: - Buttons Section
    private var actionButtons: some View {
        VStack(spacing: 25) {
            
            // UPLOAD BUTTON
            Button(action: { showingScanSubmission = true }) {
                uploadCard
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            
            // REPORTS BUTTON
            Button(action: { showingReports = true }) {
                reportsCard
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            
        }
        .padding(.top, 30)
        .padding(.bottom, 50)
    }
    
    // MARK: - Upload Card
    private var uploadCard: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.35, green: 0.55, blue: 1.0))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "viewfinder")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text("Upload medical scans for analysis")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text("Submit 2 images for processing")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 35)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Reports Card
    private var reportsCard: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.2, green: 0.65, blue: 0.35))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text("View and download patient reports")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text("Access all medical reports")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 35)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Logout Logic
    private func performLogout() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn") // IMPORTANT
        withAnimation(.easeInOut(duration: 0.5)) {
            isLoggedIn = false
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(isLoggedIn: .constant(true))
    }
}
