import Foundation
import KeychainAccess

enum KeychainHelper  {
    enum Key: String {
        case userId = "userId"
    }

    static let keychain: @Sendable () -> Keychain = {
        Keychain(accessGroup: "J4Z3PK4YF6.UGO.Pomodolog.Keychain").synchronizable(true)
    }

    
    static func clear() {
        try? keychain().removeAll()
    }
    
    static func saveUserId() throws {
        try keychain().set(UUID().uuidString, key: Key.userId.rawValue)
    }
    
    static func getUserId() throws -> String? {
        try keychain().get(Key.userId.rawValue)
    }
    
    static func deleteUserId(){
        try? keychain().remove(Key.userId.rawValue)
    }
}
