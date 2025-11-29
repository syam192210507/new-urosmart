import SwiftUI

struct ForgotPasswordView: View {
    @Binding var isPresented: Bool
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showOTPView = false
    @State private var devOtp: String? // For development only
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                    
                    Text("Forgot Password?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your mobile number and we'll send you an OTP to reset your password.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                        .padding(.horizontal)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: requestReset) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send OTP")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(phoneNumber.isEmpty || isLoading)
                    
                    Spacer()
                    
                }
                .padding()
                .navigationDestination(isPresented: $showOTPView) {
                    OTPVerificationView(phoneNumber: phoneNumber, devOtp: devOtp, isPresented: $isPresented)
                }
            }
            .navigationBarTitle("Reset Password", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Check your messages"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    // Navigate to OTP view even if no dev OTP (in prod)
                    showOTPView = true
                })
            }
        }
    }
    
    private func requestReset() {
        guard !phoneNumber.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await AuthService.shared.forgotPassword(phoneNumber: phoneNumber)
                
                // Check if result is a 6-digit OTP (simple check)
                if result.count == 6 && Int(result) != nil {
                    devOtp = result
                    // Auto-navigate for convenience in dev
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showOTPView = true
                    }
                } else {
                    // It's a message
                    alertMessage = result
                    showAlert = true
                }
                
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView(isPresented: .constant(true))
    }
}
