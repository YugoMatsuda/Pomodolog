import Foundation
import Dependencies
import SwiftUI

struct UserSettingsClient: Sendable {
    var getUserId:@Sendable () throws ->  String?
    var saveUserId: @Sendable (_ userId: String) async throws -> Void
}

extension UserSettingsClient: DependencyKey {
    static let liveValue = Self(
        getUserId: {
            try KeychainHelper.getUserId()
        },
        saveUserId: { userId in
            try KeychainHelper.saveUserId(userId)
        }
    )
}

extension DependencyValues {
    var userSettingsClient: UserSettingsClient {
        get { self[UserSettingsClient.self] }
        set { self[UserSettingsClient.self] = newValue }
    }
}
