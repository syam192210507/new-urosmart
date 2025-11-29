import SwiftUI

struct LoginView: View {
    @Binding var showSignUp: Bool
    @Binding var isLoggedIn: Bool

    @State private var email: String = UserDefaults.standard.string(forKey: "remember_email") ?? ""
    @State private var password: String = UserDefaults.standard.string(forKey: "remember_password") ?? ""
    @State private var rememberMe: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
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
            
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    
                    // LOGO
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.3, green: 0.5, blue: 1.0))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "stethoscope")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 30)
                    
                    // HEADER
                    VStack(spacing: 8) {
                        Text("Log In")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        Text("Sign in to access your medical dashboard")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    // INPUT FIELDS
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email Address")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            TextField("enter email", text: $email)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .font(.system(size: 14))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            SecureField("enter password", text: $password)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    // REMEMBER ME ROW
                    HStack {
                        HStack(spacing: 8) {
                            Button(action: {
                                rememberMe.toggle()
                            }) {
                                Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                    .foregroundColor(rememberMe ? .blue : .gray)
                                    .font(.system(size: 16))
                            }
                            
                            Text("Remember me")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("Forgot password?")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    // LOGIN BUTTON
                    Button(action: handleLogin) {
                        Text("Log In")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 8)

                    // SIGNUP FOOTER
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            withAnimation {
                                showSignUp = true
                            }
                        }) {
                            Text("Create Now")
                                .font(.caption)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .alert("Login Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Login Logic
    private func handleLogin() {
        Task {
            do {
                guard !email.isEmpty, !password.isEmpty else {
                    errorMessage = "Please enter email and password"
                    showError = true
                    return
                }
                
                _ = try await AuthService.shared.login(email: email, password: password)
                
                // Save Remember Me
                if rememberMe {
                    UserDefaults.standard.set(email, forKey: "remember_email")
                    UserDefaults.standard.set(password, forKey: "remember_password")
                }
                
                withAnimation {
                    isLoggedIn = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
