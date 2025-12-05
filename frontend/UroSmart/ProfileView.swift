import SwiftUI

struct ProfileView: View {
    @Binding var isPresented: Bool
    @Binding var isLoggedIn: Bool
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showChangePassword: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showPasswordChangeSuccess: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var isProcessing: Bool = false
    @State private var userEmail: String = "Loading..."
    
    // Responsive sizing
    private var isSmallDevice: Bool { DeviceType.current.isSmallDevice }
    private var horizontalPadding: CGFloat { ResponsiveSize.shared.horizontalPadding }
    
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
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Header
                        HStack {
                            Button(action: {
                                isPresented = false
                            }) {
                                HStack(spacing: isSmallDevice ? 6 : 8) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: isSmallDevice ? 14 : 16))
                                    Text("Back to Dashboard")
                                        .font(.system(size: isSmallDevice ? 12 : 14))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, isSmallDevice ? 12 : 16)
                                .padding(.vertical, isSmallDevice ? 6 : 8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(20)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, isSmallDevice ? 8 : 10)
                        
                        // MARK: - Main Card
                        VStack(spacing: 0) {
                            
                            // MARK: - Profile Header
                            VStack(spacing: isSmallDevice ? 12 : 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.3, green: 0.5, blue: 1.0))
                                        .frame(width: isSmallDevice ? 70 : 90, height: isSmallDevice ? 70 : 90)
                                    
                                    Image(systemName: "person.fill")
                                        .font(.system(size: isSmallDevice ? 35 : 45))
                                        .foregroundColor(.white)
                                }
                                .padding(.top, isSmallDevice ? 24 : 30)
                                
                                Text("My Profile")
                                    .font(.system(size: isSmallDevice ? 20 : 24, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .padding(.bottom, isSmallDevice ? 20 : 24)
                            
                            // MARK: - Email Section
                            VStack(alignment: .leading, spacing: isSmallDevice ? 10 : 12) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: isSmallDevice ? 16 : 18))
                                    Text("Email Address")
                                        .font(.system(size: isSmallDevice ? 14 : 16, weight: .semibold))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                
                                Text(userEmail)
                                    .font(.system(size: isSmallDevice ? 13 : 14))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, isSmallDevice ? 12 : 16)
                                    .padding(.vertical, isSmallDevice ? 10 : 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, isSmallDevice ? 16 : 20)
                            
                            Divider()
                                .padding(.horizontal, horizontalPadding)
                                .padding(.vertical, isSmallDevice ? 12 : 16)
                            
                            // MARK: - Change Password Button
                            Button(action: {
                                withAnimation {
                                    showChangePassword.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundColor(.blue)
                                        .font(.system(size: isSmallDevice ? 16 : 18))
                                    Text("Change Password")
                                        .font(.system(size: isSmallDevice ? 14 : 16, weight: .medium))
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: showChangePassword ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray)
                                        .font(.system(size: isSmallDevice ? 12 : 14))
                                }
                                .padding(.horizontal, horizontalPadding)
                                .padding(.vertical, isSmallDevice ? 10 : 12)
                            }
                            
                            // MARK: - Password Change Form
                            if showChangePassword {
                                VStack(spacing: isSmallDevice ? 12 : 16) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Current Password")
                                            .font(.system(size: isSmallDevice ? 11 : 12))
                                            .foregroundColor(.gray)
                                        
                                        SecureField("Enter current password", text: $currentPassword)
                                            .padding(.horizontal, isSmallDevice ? 12 : 16)
                                            .padding(.vertical, isSmallDevice ? 10 : 12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .font(.system(size: isSmallDevice ? 13 : 14))
                                            .disableKeyboardAccessory()
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("New Password")
                                            .font(.system(size: isSmallDevice ? 11 : 12))
                                            .foregroundColor(.gray)
                                        
                                        SecureField("Enter new password", text: $newPassword)
                                            .padding(.horizontal, isSmallDevice ? 12 : 16)
                                            .padding(.vertical, isSmallDevice ? 10 : 12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .font(.system(size: isSmallDevice ? 13 : 14))
                                            .disableKeyboardAccessory()
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Confirm New Password")
                                            .font(.system(size: isSmallDevice ? 11 : 12))
                                            .foregroundColor(.gray)
                                        
                                        SecureField("Confirm new password", text: $confirmPassword)
                                            .padding(.horizontal, isSmallDevice ? 12 : 16)
                                            .padding(.vertical, isSmallDevice ? 10 : 12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .font(.system(size: isSmallDevice ? 13 : 14))
                                            .disableKeyboardAccessory()
                                    }
                                    
                                    Button(action: handleChangePassword) {
                                        if isProcessing {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Text("Update Password")
                                                .font(.system(size: isSmallDevice ? 14 : 16, weight: .medium))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, isSmallDevice ? 12 : 14)
                                    .background(isProcessing ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .disabled(isProcessing)
                                }
                                .padding(.horizontal, horizontalPadding)
                                .padding(.vertical, isSmallDevice ? 12 : 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            Divider()
                                .padding(.horizontal, horizontalPadding)
                                .padding(.vertical, isSmallDevice ? 12 : 16)
                            
                            // MARK: - Delete Account Button
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(isProcessing ? .gray : .red)
                                        .font(.system(size: isSmallDevice ? 16 : 18))
                                    Text("Delete Account")
                                        .font(.system(size: isSmallDevice ? 14 : 16, weight: .medium))
                                        .foregroundColor(isProcessing ? .gray : .red)
                                    Spacer()
                                }
                                .padding(.horizontal, horizontalPadding)
                                .padding(.vertical, isSmallDevice ? 10 : 12)
                            }
                            .disabled(isProcessing)
                            
                            Text("This action cannot be undone. All your data will be permanently deleted.")
                                .font(.system(size: isSmallDevice ? 10 : 11))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, horizontalPadding)
                                .padding(.top, 8)
                                .padding(.bottom, isSmallDevice ? 16 : 20)
                            
                            Divider()
                                .padding(.horizontal, horizontalPadding)
                                .padding(.vertical, isSmallDevice ? 12 : 16)
                            
                            // MARK: - Developer Debug Section
                            VStack(alignment: .leading, spacing: isSmallDevice ? 8 : 12) {
                                Text("Developer Tools")
                                    .font(.system(size: isSmallDevice ? 12 : 14, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, horizontalPadding)
                                
                                Button(action: clearLocalData) {
                                    HStack {
                                        Image(systemName: "trash.slash.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: isSmallDevice ? 14 : 16))
                                        Text("Clear Local Data")
                                            .font(.system(size: isSmallDevice ? 13 : 14, weight: .medium))
                                            .foregroundColor(.orange)
                                        Spacer()
                                    }
                                    .padding(.horizontal, horizontalPadding)
                                    .padding(.vertical, isSmallDevice ? 8 : 10)
                                }
                                
                                Text("Clears all offline data (cache, credentials, reports). Use this to reset the app without reinstalling.")
                                    .font(.system(size: isSmallDevice ? 9 : 10))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, horizontalPadding)
                                    .padding(.bottom, isSmallDevice ? 24 : 30)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(ResponsiveSize.shared.cardCornerRadius)
                        .padding(.horizontal, isSmallDevice ? 12 : 16)
                        .padding(.top, isSmallDevice ? 16 : 20)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Load user email synchronously from cache
            Task {
                if let user = await AuthService.shared.getCurrentUser() {
                    await MainActor.run {
                        userEmail = user.email
                    }
                } else {
                    await MainActor.run {
                        userEmail = "No email available"
                    }
                }
            }
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                handleDeleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.")
        }
        .alert("Success", isPresented: $showPasswordChangeSuccess) {
            Button("OK", role: .cancel) {
                // Clear fields
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
                showChangePassword = false
            }
        } message: {
            Text("Your password has been successfully changed.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Change Password Logic
    private func handleChangePassword() {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all password fields"
            showError = true
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords do not match"
            showError = true
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "New password must be at least 6 characters"
            showError = true
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                try await AuthService.shared.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                
                await MainActor.run {
                    isProcessing = false
                    showPasswordChangeSuccess = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Delete Account Logic
    private func handleDeleteAccount() {
        isProcessing = true
        
        Task {
            do {
                try await AuthService.shared.deleteAccount()
                
                await MainActor.run {
                    isProcessing = false
                    // Clear all local data
                    UserDefaults.standard.set(false, forKey: "isLoggedIn")
                    UserDefaults.standard.removeObject(forKey: "cached_user")
                    UserDefaults.standard.removeObject(forKey: "last_user_id")
                    
                    // Logout and return to login screen
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLoggedIn = false
                    }
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    isProcessing = false
                    switch error {
                    case .offline:
                        errorMessage = "Cannot delete account while offline. Please connect to the internet and try again."
                    case .unauthorized:
                        errorMessage = "Session expired. Please log in again and try deleting your account."
                    default:
                        errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    }
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Clear Local Data Logic
    private func clearLocalData() {
        Task {
            await MainActor.run {
                // Clear all UserDefaults
                UserDefaults.standard.removeObject(forKey: "cached_user")
                UserDefaults.standard.removeObject(forKey: "last_user_id")
                UserDefaults.standard.removeObject(forKey: "isLoggedIn")
                
                // Clear all reports
                ReportStore.shared.clear()
                
                print("🗑️ Cleared all local data")
                print("   - User cache")
                print("   - Reports")
                print("   - Login state")
                print("ℹ️ Note: Keychain credentials kept for 'Remember Me'")
                
                // Logout and return to login screen
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoggedIn = false
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView(isPresented: .constant(true), isLoggedIn: .constant(true))
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("iPhone SE")
            
            ProfileView(isPresented: .constant(true), isLoggedIn: .constant(true))
                .previewDevice("iPhone 14")
                .previewDisplayName("iPhone 14")
        }
    }
}
