import SwiftUI

struct SignUpView: View {
    @Binding var showSignUp: Bool
    @Binding var isLoggedIn: Bool
    @State private var phoneNumber: String = ""
    @State private var emailAddress: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    
    // Responsive sizing
    private var isSmallDevice: Bool { DeviceType.current.isSmallDevice }
    private var horizontalPadding: CGFloat { ResponsiveSize.shared.horizontalPadding }
    
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
            
            ScrollView {
                VStack {
                    Spacer(minLength: isSmallDevice ? 20 : 40)
                    
                    VStack(spacing: isSmallDevice ? 16 : 20) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.3, green: 0.5, blue: 1.0))
                                .frame(width: isSmallDevice ? 50 : 60, height: isSmallDevice ? 50 : 60)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: isSmallDevice ? 24 : 30))
                                .foregroundColor(.white)
                        }
                        .padding(.top, isSmallDevice ? 24 : 30)
                        
                        Text("Create an Account")
                            .font(.system(size: isSmallDevice ? 20 : 22, weight: .semibold))
                            .foregroundColor(.black)
                        
                        VStack(spacing: isSmallDevice ? 12 : 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Phone No.")
                                    .font(.system(size: isSmallDevice ? 11 : 12))
                                    .foregroundColor(.gray)
                                
                                TextField("Phone No.", text: $phoneNumber)
                                    .padding(.horizontal, isSmallDevice ? 12 : 16)
                                    .padding(.vertical, isSmallDevice ? 10 : 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .font(.system(size: isSmallDevice ? 13 : 14))
                                    .keyboardType(.phonePad)
                                    .disableKeyboardAccessory()
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email Address")
                                    .font(.system(size: isSmallDevice ? 11 : 12))
                                    .foregroundColor(.gray)
                                
                                TextField("Enter email", text: $emailAddress)
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
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Confirm Password")
                                    .font(.system(size: isSmallDevice ? 11 : 12))
                                    .foregroundColor(.gray)
                                
                                SecureField("confirm password", text: $confirmPassword)
                                    .padding(.horizontal, isSmallDevice ? 12 : 16)
                                    .padding(.vertical, isSmallDevice ? 10 : 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .font(.system(size: isSmallDevice ? 13 : 14))
                                    .disableKeyboardAccessory()
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        Button(action: {
                            Task {
                                do {
                                    guard !phoneNumber.isEmpty, !emailAddress.isEmpty, !password.isEmpty else {
                                        await MainActor.run {
                                            errorMessage = "Please fill in all fields"
                                            showError = true
                                        }
                                        return
                                    }
                                    
                                    guard password == confirmPassword else {
                                        await MainActor.run {
                                            errorMessage = "Passwords do not match"
                                            showError = true
                                        }
                                        return
                                    }
                                    
                                    _ = try await AuthService.shared.signup(
                                        phoneNumber: phoneNumber,
                                        email: emailAddress,
                                        password: password
                                    )
                                    
                                    await MainActor.run {
                                        showSuccess = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            withAnimation {
                                                isLoggedIn = true
                                            }
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        errorMessage = "Signup failed: \(error.localizedDescription)"
                                        showError = true
                                    }
                                }
                            }
                        }) {
                            Text("Sign Up")
                                .font(.system(size: isSmallDevice ? 14 : 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, isSmallDevice ? 12 : 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 8)
                        
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.system(size: isSmallDevice ? 11 : 12))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                withAnimation {
                                    showSignUp = false
                                }
                            }) {
                                Text("Log In")
                                    .font(.system(size: isSmallDevice ? 11 : 12))
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.bottom, isSmallDevice ? 24 : 30)
                    }
                    .background(Color.white)
                    .cornerRadius(ResponsiveSize.shared.cardCornerRadius)
                    .padding(.horizontal, horizontalPadding)
                    
                    Spacer(minLength: isSmallDevice ? 20 : 40)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Account created successfully! Logging you in...")
        }
    }
}
    