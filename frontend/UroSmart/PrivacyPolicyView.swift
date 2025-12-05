import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("Last updated: November 27, 2025")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Group {
                        Text("1. Introduction")
                            .font(.headline)
                        Text("Welcome to UroSmart. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you as to how we look after your personal data when you visit our application and tell you about your privacy rights and how the law protects you.")
                        
                        Text("2. Data We Collect")
                            .font(.headline)
                        Text("We may collect, use, store and transfer different kinds of personal data about you which we have grouped together follows: Identity Data, Contact Data, and Medical Data (uploaded scans and reports).")
                        
                        Text("3. How We Use Your Data")
                            .font(.headline)
                        Text("We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances: To provide the medical analysis service you requested.")
                        
                        Text("4. Data Security")
                            .font(.headline)
                        Text("We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way, altered or disclosed.")
                    }
                    .font(.body)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("Privacy Policy", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}
