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
                    Spacer(minLength: 50)
                    
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.3, green: 0.5, blue: 1.0))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "stethoscope")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 30)
                        
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
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
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
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        HStack {
                            Button(action: {
                                rememberMe.toggle()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .foregroundColor(rememberMe ? .blue : .gray)
                                        .font(.system(size: 16))
                                    
                                    Text("Remember me")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showForgotPassword = true
                            }) {
                                Text("Forgot password?")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .sheet(isPresented: $showForgotPassword) {
                                ForgotPasswordView(isPresented: $showForgotPassword)
                            }
                        }
                        .padding(.horizontal, 8)
                        
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
                    
                    Spacer(minLength: 50)
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
                    // Handle Remember Me
                    if rememberMe {
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    } else {
                        UserDefaults.standard.set(false, forKey: "isLoggedIn")
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
