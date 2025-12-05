import SwiftUI

struct AuthenticationView: View {
    @Binding var isLoggedIn: Bool
    @State private var showSignUp: Bool = false
    @State private var showForgotPassword: Bool = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var errorMessage: String = ""
    
    @State private var showLogin: Bool = false
    
    // Responsive sizing
    private var isSmallDevice: Bool { DeviceType.current.isSmallDevice }
    private var horizontalPadding: CGFloat { ResponsiveSize.shared.horizontalPadding }
    
    init(isLoggedIn: Binding<Bool>) {
        self._isLoggedIn = isLoggedIn
        
        // Load saved credentials from Keychain
        let credentials = KeychainManager.shared.loadCredentials()
        if let savedEmail = credentials.email, let savedPassword = credentials.password {
            self._email = State(initialValue: savedEmail)
            self._password = State(initialValue: savedPassword)
            self._rememberMe = State(initialValue: true)
        }
    }

    var body: some View {
        if !showLogin {
            GetStartedView(showLogin: $showLogin)
                .transition(.opacity)
        } else if showSignUp {
            SignUpView(showSignUp: $showSignUp, isLoggedIn: $isLoggedIn)
                .transition(.move(edge: .trailing))
        } else {
            loginContent
                .transition(.opacity)
        }
    }
    
    var loginContent: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.4, blue: 1.0),
                    Color(red: 0.0, green: 0.8, blue: 0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack {
                    Spacer(minLength: isSmallDevice ? 30 : 50)
                    
                    VStack(spacing: isSmallDevice ? 16 : 20) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.3, green: 0.5, blue: 1.0))
                                .frame(width: isSmallDevice ? 50 : 60, height: isSmallDevice ? 50 : 60)
                            
                            Image(systemName: "stethoscope")
                                .font(.system(size: isSmallDevice ? 24 : 30))
                                .foregroundColor(.white)
                        }
                        .padding(.top, isSmallDevice ? 24 : 30)
                        
                        VStack(spacing: 8) {
                            Text("Log In")
                                .font(.system(size: isSmallDevice ? 20 : 22, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("Sign in to access your medical dashboard")
                                .font(.system(size: isSmallDevice ? 12 : 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.9)
                        }
                        
                        VStack(spacing: isSmallDevice ? 12 : 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email Address")
                                    .font(.system(size: isSmallDevice ? 11 : 12))
                                    .foregroundColor(.gray)
                                
                                TextField("enter email", text: $email)
                                    .padding(.horizontal, isSmallDevice ? 12 : 16)
                                    .padding(.vertical, isSmallDevice ? 10 : 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .font(.system(size: isSmallDevice ? 13 : 14))
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .disableKeyboardAccessory()
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password")
                                    .font(.system(size: isSmallDevice ? 11 : 12))
                                    .foregroundColor(.gray)
                                
                                SecureField("enter password", text: $password)
                                    .padding(.horizontal, isSmallDevice ? 12 : 16)
                                    .padding(.vertical, isSmallDevice ? 10 : 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .font(.system(size: isSmallDevice ? 13 : 14))
                                    .disableKeyboardAccessory()
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: isSmallDevice ? 11 : 12))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        HStack {
                            Button(action: {
                                rememberMe.toggle()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .foregroundColor(rememberMe ? .blue : .gray)
                                        .font(.system(size: isSmallDevice ? 14 : 16))
                                    
                                    Text("Remember me")
                                        .font(.system(size: isSmallDevice ? 11 : 12))
                                        .foregroundColor(.gray)
                                    }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showForgotPassword = true
                            }) {
                                Text("Forgot password?")
                                    .font(.system(size: isSmallDevice ? 11 : 12))
                                    .foregroundColor(.blue)
                            }
                            .sheet(isPresented: $showForgotPassword) {
                                ForgotPasswordView(isPresented: $showForgotPassword)
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        Button(action: handleLogin) {
                            Text("Log In")
                                .font(.system(size: isSmallDevice ? 14 : 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, isSmallDevice ? 12 : 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 8)
                        
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(.system(size: isSmallDevice ? 11 : 12))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                withAnimation {
                                    showSignUp = true
                                }
                            }) {
                                Text("Create Now")
                                    .font(.system(size: isSmallDevice ? 11 : 12))
                                    .foregroundColor(.red)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.bottom, isSmallDevice ? 24 : 30)
                    }
                    .background(Color.white)
                    .cornerRadius(ResponsiveSize.shared.cardCornerRadius)
                    .padding(.horizontal, horizontalPadding)
                    
                    Spacer(minLength: isSmallDevice ? 30 : 50)
                }
            }
        }
    }
    
    private func handleLogin() {
        // Use AuthService for login
        Task {
            do {
                // Always use AuthService (which calls backend when online)
                _ = try await AuthService.shared.login(email: email, password: password)
                
                await MainActor.run {
                    // Handle Remember Me - save to Keychain (secure) instead of UserDefaults
                    if rememberMe {
                        let saved = KeychainManager.shared.saveCredentials(email: email, password: password)
                        if saved {
                            print("✅ Credentials saved securely to Keychain")
                        } else {
                            print("⚠️ Failed to save credentials to Keychain")
                        }
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    } else {
                        // User unchecked Remember Me - remove from Keychain
                        KeychainManager.shared.deleteCredentials()
                        UserDefaults.standard.set(false, forKey: "isLoggedIn")
                    }
                    
                    // Start federated learning service (if enabled)
                    if AppConfig.enableFederatedLearning {
                        FederatedBackgroundService.shared.start()
                    }
                    
                    withAnimation {
                        isLoggedIn = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView(isLoggedIn: .constant(false))
    }
}
