import SwiftUI

struct SidebarView: View {
    @Binding var isOpen: Bool
    @State private var showPrivacyPolicy = false
    @State private var showTermsConditions = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            if isOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isOpen = false
                        }
                    }
            }
            
            // Sidebar content
            HStack {
                VStack(alignment: .leading, spacing: 30) {
                    // Header
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Menu")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                    
                    // Menu Items
                    Button(action: { showPrivacyPolicy = true }) {
                        HStack(spacing: 15) {
                            Image(systemName: "hand.raised.fill")
                                .frame(width: 24)
                            Text("Privacy Policy")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.black)
                    }
                    .sheet(isPresented: $showPrivacyPolicy) {
                        PrivacyPolicyView()
                    }
                    
                    Button(action: { showTermsConditions = true }) {
                        HStack(spacing: 15) {
                            Image(systemName: "doc.text.fill")
                                .frame(width: 24)
                            Text("Terms & Conditions")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.black)
                    }
                    .sheet(isPresented: $showTermsConditions) {
                        TermsConditionsView()
                    }
                    
                    Spacer()
                    
                    // Footer
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
                .frame(width: 270)
                .background(Color.white)
                .offset(x: isOpen ? 0 : -270)
                .animation(.default, value: isOpen)
                
                Spacer()
            }
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(isOpen: .constant(true))
    }
}
