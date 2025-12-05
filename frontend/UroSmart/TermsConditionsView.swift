import SwiftUI

struct TermsConditionsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms and Conditions")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("Last updated: November 27, 2025")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Group {
                        Text("1. Agreement to Terms")
                            .font(.headline)
                        Text("By accessing our application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.")
                        
                        Text("2. Medical Disclaimer")
                            .font(.headline)
                        Text("UroSmart provides analysis for informational purposes only. It is NOT a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider.")
                        
                        Text("3. User Accounts")
                            .font(.headline)
                        Text("When you create an account with us, you must provide us information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms.")
                        
                        Text("4. Intellectual Property")
                            .font(.headline)
                        Text("The Service and its original content, features and functionality are and will remain the exclusive property of UroSmart and its licensors.")
                    }
                    .font(.body)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("Terms & Conditions", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct TermsConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsConditionsView()
    }
}
