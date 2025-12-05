import Foundation
import Security

/// Secure wrapper for iOS Keychain to store sensitive credentials
final class KeychainManager {
    
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Keys
    private enum KeychainKey: String {
        case userEmail = "com.urosmart.email"
        case userPassword = "com.urosmart.password"
    }
    
    // MARK: - Public Methods
    
    /// Save credentials to Keychain
    func saveCredentials(email: String, password: String) -> Bool {
        // Save email
        let emailSaved = save(key: .userEmail, value: email)
        // Save password
        let passwordSaved = save(key: .userPassword, value: password)
        
        return emailSaved && passwordSaved
    }
    
    /// Load credentials from Keychain
    func loadCredentials() -> (email: String?, password: String?) {
        let email = load(key: .userEmail)
        let password = load(key: .userPassword)
        return (email, password)
    }
    
    /// Delete credentials from Keychain
    func deleteCredentials() {
        delete(key: .userEmail)
        delete(key: .userPassword)
    }
    
    /// Check if credentials exist
    func hasCredentials() -> Bool {
        let credentials = loadCredentials()
        return credentials.email != nil && credentials.password != nil
    }
    
    // MARK: - Private Methods
    
    private func save(key: KeychainKey, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete existing item first
        delete(key: key)
        
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Add to keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func load(key: KeychainKey) -> String? {
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
