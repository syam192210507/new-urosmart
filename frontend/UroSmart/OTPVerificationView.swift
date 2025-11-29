import SwiftUI

struct OTPVerificationView: View {
    let phoneNumber: String
    let devOtp: String? // For development convenience
    @Binding var isPresented: Bool
    
    @State private var otp = ""
    @State private var navigateToReset = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            Text("Enter OTP")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("We sent a code to \(phoneNumber)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let devOtp = devOtp {
                Text("Dev OTP: \(devOtp)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.bottom, 4)
                    .onAppear {
                        // Auto-fill for convenience
                        otp = devOtp
                    }
            }
            
            TextField("000000", text: $otp)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .onChange(of: otp) { _, newValue in
                    if newValue.count > 6 {
                        otp = String(newValue.prefix(6))
                    }
                }
            
            Button(action: {
                if otp.count == 6 {
                    navigateToReset = true
                }
            }) {
                Text("Verify")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(otp.count != 6)
            
            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $navigateToReset) {
            ResetPasswordView(phoneNumber: phoneNumber, otp: otp, isPresented: $isPresented)
        }
        .navigationBarTitle("Verification", displayMode: .inline)
    }
}

struct OTPVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        OTPVerificationView(phoneNumber: "+1234567890", devOtp: "123456", isPresented: .constant(true))
    }
}
