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
        
        // Try backend first if online
        if connectivity.isOnline {
            do {
                user = try await network.signup(phoneNumber: phoneNumber, email: email, password: password)
                print("✅ Backend signup successful")
            } catch {
                print("⚠️ Backend signup failed, using offline: \(error)")
                // Fall through to offline signup
            }
        }
        
        // Offline signup or backend fallback
        if user == nil {
            user = User(
                id: Int.random(in: 1...10_000),
                phone_number: phoneNumber,
                email: email,
                created_at: ISO8601DateFormatter().string(from: Date())
            )
            print("✅ Offline signup successful")
        }
        
        // Always save locally (overwrites previous credentials)
        saveCredentials(email: email, password: password, phoneNumber: phoneNumber)
        cacheUser(user!)
        
        return user!
    }
    
    
    // MARK: - Login
    func login(email: String, password: String) async throws -> User {
        var user: User?
        
        // Try backend first if online
        if connectivity.isOnline {
            do {
                user = try await network.login(email: email, password: password)
                // Save to local cache
                saveCredentials(email: email, password: password, phoneNumber: user!.phone_number)
                cacheUser(user!)
                print("✅ Backend login successful")
                return user!
            } catch {
                print("⚠️ Backend login failed, trying offline: \(error)")
                // Fall through to offline login
            }
        }
        
        // Offline login
        guard
            let storedEmail = keychain.get(forKey: KeychainHelper.Key.email),
            let storedPassword = keychain.get(forKey: KeychainHelper.Key.password),
            email == storedEmail,
            password == storedPassword
        else {
            throw AuthError.invalidCredentials
        }
        
        if let cachedUser = getCachedUser() {
            print("✅ Offline login successful")
            return cachedUser
        } else {
            // Create fallback user if cache was cleared
            let fallbackUser = User(
                id: Int.random(in: 1...10_000),
                phone_number: keychain.get(forKey: KeychainHelper.Key.phoneNumber) ?? "",
                email: storedEmail,
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
    func logout() {
        _ = keychain.delete(forKey: KeychainHelper.Key.email)
        _ = keychain.delete(forKey: KeychainHelper.Key.password)
        _ = keychain.delete(forKey: KeychainHelper.Key.phoneNumber)
        _ = keychain.delete(forKey: KeychainHelper.Key.accessToken)
        UserDefaults.standard.removeObject(forKey: "cached_user")
    }
    
    // MARK: - Helpers
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

