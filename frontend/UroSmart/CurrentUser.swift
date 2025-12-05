import Foundation

/// Helper to get current logged-in user ID
struct CurrentUser {
    static func getUserId() -> Int? {
        guard let data = UserDefaults.standard.data(forKey: "cached_user"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user.id
    }
}
