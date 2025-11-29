import SwiftUI

@main
struct UroSmartApp: App {

    @State private var isLoggedIn: Bool = false

    init() {
        // Check login status at app launch
        let stored = UserDefaults.standard.bool(forKey: "isLoggedIn")
        _isLoggedIn = State(initialValue: stored)
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                DashboardView(isLoggedIn: $isLoggedIn)   // ✅ binding passed
                    .onAppear { print("➡️ Loaded Dashboard (already logged in)") }
            } else {
                AuthenticationView(isLoggedIn: $isLoggedIn) // ✅ binding passed
                    .onAppear { print("➡️ Showing offline authentication") }
            }
        }
    }
}
