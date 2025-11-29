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
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.3, green: 0.5, blue: 1.0))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 30)
                    
                    Text("Create an Account")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Phone No.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            TextField("Phone No.", text: $phoneNumber)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .font(.system(size: 14))
                                .keyboardType(.phonePad)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email Address")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            TextField("Enter email", text: $emailAddress)
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
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            SecureField("confirm password", text: $confirmPassword)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .font(.system(size: 14))
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
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 8)
                    
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            withAnimation {
                                showSignUp = false
                            }
                        }) {
                            Text("Log In")
                                .font(.caption)
                                .foregroundColor(.blue)
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
    