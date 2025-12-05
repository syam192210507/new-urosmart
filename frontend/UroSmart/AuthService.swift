import Foundation

/// Offline-first authentication with backend sync
actor AuthService {
    static let shared = AuthService()
    
    private let keychain = KeychainHelper.shared
    private let network = NetworkService.shared
    private let connectivity = ConnectivityMonitor.shared
    
    private init() {}
    
    // MARK: - Signup
    func signup(phoneNumber: String, email: String, password: String) async throws -> User {
        var user: User?
        var shouldFallbackToOffline = false
        
        // Try backend first if online
        if connectivity.isOnline {
            do {
                user = try await network.signup(phoneNumber: phoneNumber, email: email, password: password)
                print("✅ Backend signup successful")
            } catch let error as NetworkError {
                switch error {
                case .offline:
                    print("⚠️ Network unavailable, using offline mode")
                    shouldFallbackToOffline = true
                default:
                    // Server errors (validation, duplicate email, etc) - don't fallback
                    print("❌ Backend signup error: \(error.localizedDescription)")
                    throw error
                }
            } catch let error as URLError {
                // Network connection errors - fallback to offline
                print("⚠️ Connection error (\(error.code.rawValue)), using offline mode")
                shouldFallbackToOffline = true
            } catch {
                // Unknown errors - log and throw
                print("❌ Unexpected signup error: \(error)")
                throw error
            }
        } else {
            print("📴 Device offline, using offline signup")
            shouldFallbackToOffline = true
        }
        
        // Offline signup only if no backend user AND offline/network error
        if user == nil && (shouldFallbackToOffline || !connectivity.isOnline) {
            user = User(
                id: Int.random(in: 1...10_000),
                phone_number: phoneNumber,
                email: email,
                created_at: ISO8601DateFormatter().string(from: Date())
            )
            print("✅ Offline signup successful")
        }
        
        guard let finalUser = user else {
            throw AuthError.invalidCredentials
        }
        
        // Always save locally
        saveCredentials(email: email, password: password, phoneNumber: phoneNumber)
        
        // Clear old reports ONLY if switching users
        await clearReportsIfUserChanged(newUserId: finalUser.id)
        
        cacheUser(finalUser)
        
        return finalUser
    }
    
    
    // MARK: - Login
    func login(email: String, password: String) async throws -> User {
        var user: User?
        var shouldTryOffline = false
        
        // Try backend first if online
        if connectivity.isOnline {
            do {
                user = try await network.login(email: email, password: password)
                // Save to local cache
                saveCredentials(email: email, password: password, phoneNumber: user!.phone_number)
                
                // Clear old reports ONLY if switching users
                await clearReportsIfUserChanged(newUserId: user!.id)
                
                cacheUser(user!)
                
                print("✅ Backend login successful")
                return user!
            } catch let error as NetworkError {
                switch error {
                case .offline:
                    print("⚠️ Network unavailable, trying offline login")
                    shouldTryOffline = true
                default:
                    // Server errors (invalid credentials, etc) - try offline as fallback
                    print("⚠️ Backend login error: \(error.localizedDescription), trying offline")
                    shouldTryOffline = true
                }
            } catch let error as URLError {
                print("⚠️ Connection error (\(error.code.rawValue)), trying offline login")
                shouldTryOffline = true
            } catch {
                print("⚠️ Unexpected login error: \(error), trying offline")
                shouldTryOffline = true
            }
        } else {
            print("📴 Device offline, using offline login")
            shouldTryOffline = true
        }
        
        // Offline login (only if we should try offline)
        if !shouldTryOffline {
            throw AuthError.invalidCredentials
        }
        
        // Check credentials from KeychainHelper (used by AuthService)
        var storedEmail = keychain.get(forKey: KeychainHelper.Key.email)
        var storedPassword = keychain.get(forKey: KeychainHelper.Key.password)
        
        print("🔍 Offline login attempt:")
        print("   Input email: \(email)")
        print("   KeychainHelper email: \(storedEmail ?? "nil")")
        print("   KeychainHelper password exists: \(storedPassword != nil)")
        
        // Also check KeychainManager (used by AuthenticationView "Remember Me")
        let managerCredentials = KeychainManager.shared.loadCredentials()
        print("   KeychainManager email: \(managerCredentials.email ?? "nil")")
        print("   KeychainManager password exists: \(managerCredentials.password != nil)")
        
        if storedEmail == nil { storedEmail = managerCredentials.email }
        if storedPassword == nil { storedPassword = managerCredentials.password }
        
        // SECURITY: Must have stored credentials to verify offline login
        guard let finalStoredEmail = storedEmail, 
              let finalStoredPassword = storedPassword else {
            print("❌ No stored credentials - cannot verify offline login")
            print("   Please connect to the internet to login for the first time")
            throw AuthError.invalidCredentials
        }
        
        print("   Final stored email: \(finalStoredEmail)")
        print("   Email match: \(email == finalStoredEmail)")
        print("   Password match: \(password == finalStoredPassword)")
        
        // Verify credentials match stored values
        guard email == finalStoredEmail && password == finalStoredPassword else {
            print("❌ Credentials mismatch")
            throw AuthError.invalidCredentials
        }
        
        print("✅ Credentials verified for offline login")
        
        if let cachedUser = getCachedUser() {
            // User already cached, no need to clear (same user)
            print("✅ Offline login successful")
            return cachedUser
        } else {
            // Create fallback user if cache was cleared
            let fallbackUser = User(
                id: Int.random(in: 1...10_000),
                phone_number: keychain.get(forKey: KeychainHelper.Key.phoneNumber) ?? "",
                email: storedEmail ?? email,
                created_at: ISO8601DateFormatter().string(from: Date())
            )
            cacheUser(fallbackUser)
            print("✅ Offline login successful (fallback)")
            return fallbackUser
        }
    }
    
    // MARK: - Password Reset
    func forgotPassword(phoneNumber: String) async throws -> String {
        return try await network.forgotPassword(phoneNumber: phoneNumber)
    }
    
    func resetPassword(phoneNumber: String, otp: String, newPassword: String) async throws {
        try await network.resetPassword(phoneNumber: phoneNumber, otp: otp, newPassword: newPassword)
    }
    
    // MARK: - Logout
    func logout() async {
        // Clear authentication credentials
        // We keep these to allow offline login even after logout
        // _ = keychain.delete(forKey: KeychainHelper.Key.email)
        // _ = keychain.delete(forKey: KeychainHelper.Key.password)
        // _ = keychain.delete(forKey: KeychainHelper.Key.phoneNumber)
        _ = keychain.delete(forKey: KeychainHelper.Key.accessToken)
        UserDefaults.standard.removeObject(forKey: "cached_user")
        UserDefaults.standard.removeObject(forKey: "last_user_id") // Clear user tracking
        
        // Clear all reports on logout
        await MainActor.run {
            ReportStore.shared.clear()
        }
    }
    
    // MARK: - Helpers
    
    /// Clear reports only if the user has changed
    /// Clear reports only if the user has changed
    private func clearReportsIfUserChanged(newUserId: Int) async {
        let lastUserId = UserDefaults.standard.integer(forKey: "last_user_id")
        
        if lastUserId != 0 && lastUserId != newUserId {
            // Different user - clear old reports
            await MainActor.run {
                ReportStore.shared.clear()
                print("🔄 Cleared reports from previous user (\(lastUserId) → \(newUserId))")
            }
        }
        
        // Save current user ID
        UserDefaults.standard.set(newUserId, forKey: "last_user_id")
    }
    private func saveCredentials(email: String, password: String, phoneNumber: String) {
        _ = keychain.save(email, forKey: KeychainHelper.Key.email)
        _ = keychain.save(password, forKey: KeychainHelper.Key.password)
        _ = keychain.save(phoneNumber, forKey: KeychainHelper.Key.phoneNumber)
    }
    
    private func cacheUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "cached_user")
        }
    }
    
    private func getCachedUser() -> User? {
        guard
            let data = UserDefaults.standard.data(forKey: "cached_user"),
            let user = try? JSONDecoder().decode(User.self, from: data)
        else {
            return nil
        }
        return user
    }
    
    /// Get current logged in user (synchronous)
    func getCurrentUser() -> User? {
        return getCachedUser()
    }
    
    // MARK: - Profile Management
    
    /// Change user password
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let email = keychain.get(forKey: KeychainHelper.Key.email),
              let storedPassword = keychain.get(forKey: KeychainHelper.Key.password) else {
            throw AuthError.invalidCredentials
        }
        
        // Verify current password
        guard currentPassword == storedPassword else {
            throw AuthError.invalidCredentials
        }
        
        // Try to update on backend if online
        if connectivity.isOnline {
            do {
                try await network.changePassword(email: email, currentPassword: currentPassword, newPassword: newPassword)
                print("✅ Password changed on backend")
            } catch {
                print("⚠️ Backend password change failed: \(error.localizedDescription)")
                // Continue to update locally even if backend fails
            }
        }
        
        // Update local storage
        _ = keychain.save(newPassword, forKey: KeychainHelper.Key.password)
        
        // Update KeychainManager as well for Remember Me feature
        _ = KeychainManager.shared.saveCredentials(email: email, password: newPassword)
        
        print("✅ Password updated locally")
    }
    
    /// Delete user account
    func deleteAccount() async throws {
        // Try to delete on backend if online
        if connectivity.isOnline {
            do {
                try await network.deleteAccount()
                print("✅ Account deleted from backend")
            } catch {
                print("⚠️ Backend account deletion failed: \(error.localizedDescription)")
                throw error
            }
        } else {
            throw NetworkError.offline
        }
        
        // Clear all local data
        _ = keychain.delete(forKey: KeychainHelper.Key.email)
        _ = keychain.delete(forKey: KeychainHelper.Key.password)
        _ = keychain.delete(forKey: KeychainHelper.Key.phoneNumber)
        _ = keychain.delete(forKey: KeychainHelper.Key.accessToken)
        UserDefaults.standard.removeObject(forKey: "cached_user")
        UserDefaults.standard.removeObject(forKey: "last_user_id")
        
        // Clear KeychainManager as well
        KeychainManager.shared.deleteCredentials()
        
        // Clear all reports
        await MainActor.run {
            ReportStore.shared.clear()
        }
        
        print("✅ Local data cleared")
    }
    
    // MARK: - Sync
    
    /// Syncs an offline-created user to the backend
    func syncUser() async {
        guard connectivity.isOnline else { return }
        
        // Check if we have a user but no access token (offline-only state)
        guard getCachedUser() != nil,
              keychain.get(forKey: KeychainHelper.Key.accessToken) == nil,
              let email = keychain.get(forKey: KeychainHelper.Key.email),
              let password = keychain.get(forKey: KeychainHelper.Key.password),
              let phoneNumber = keychain.get(forKey: KeychainHelper.Key.phoneNumber)
        else {
            return
        }
        
        print("🔄 Syncing offline user to backend...")
        
        do {
            // Try signup first
            let syncedUser = try await network.signup(phoneNumber: phoneNumber, email: email, password: password)
            
            // Update local cache with backend ID
            cacheUser(syncedUser)
            print("✅ User synced successfully (Created)")
            
        } catch let error as NetworkError {
            // If user already exists (409), try login
            print("⚠️ Signup failed during sync (\(error)), trying login...")
            
            do {
                let loggedInUser = try await network.login(email: email, password: password)
                cacheUser(loggedInUser)
                print("✅ User synced successfully (Logged in)")
            } catch let loginError as NetworkError {
                print("❌ Failed to sync user via login: \(loginError)")
                
                // If login fails due to invalid response or credentials, 
                // the offline password likely doesn't match backend password.
                // Clear the offline state to force fresh login.
                switch loginError {
                case .invalidResponse, .offline:
                    print("💡 Password mismatch detected. Clearing offline cache.")
                    print("🔄 User will need to login fresh with correct credentials.")
                    
                    // Clear offline state
                    UserDefaults.standard.removeObject(forKey: "cached_user")
                    _ = keychain.delete(forKey: KeychainHelper.Key.accessToken)
                    
                    // Note: We keep email/password in keychain for "Remember Me" feature
                    // The user can still use them or enter new ones
                    
                default:
                    print("⚠️ Unexpected login error: \(loginError)")
                }
            } catch {
                print("❌ Failed to sync user: \(error)")
            }
        } catch {
            print("❌ Failed to sync user: \(error)")
        }
    }
}

// MARK: - Models
struct User: Codable {
    let id: Int
    let phone_number: String
    let email: String
    let created_at: String
}

// MARK: - Errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyExists
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyExists:
            return "An account already exists on this device"
        }
    }
}

