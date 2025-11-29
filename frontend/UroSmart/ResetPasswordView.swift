import SwiftUI

struct ResetPasswordView: View {
    let phoneNumber: String
    let otp: String
    @Binding var isPresented: Bool
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Create New Password")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Button(action: resetPassword) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Reset Password")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(newPassword.isEmpty || confirmPassword.isEmpty || isLoading)
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitle("New Password", displayMode: .inline)
    }
    
    private func resetPassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await AuthService.shared.resetPassword(phoneNumber: phoneNumber, otp: otp, newPassword: newPassword)
                successMessage = "Password reset successfully. You can now login."
                isLoading = false
                
                // Dismiss after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // Dismiss the entire sheet to return to login
                    isPresented = false
                }
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView(phoneNumber: "+1234567890", otp: "123456", isPresented: .constant(true))
    }
}
