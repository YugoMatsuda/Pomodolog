import Foundation
import Dependencies
import SwiftUI

struct UserSettingsClient: Sendable {
    var getUserId:@Sendable () throws ->  String?
    var saveUserId: @Sendable () async throws -> Void
}

extension UserSettingsClient: DependencyKey {
    static let liveValue = Self(
        getUserId: {
            try KeychainHelper.getUserId()
        },
        saveUserId: {
            try KeychainHelper.saveUserId()
        }
    )
}

extension DependencyValues {
    var userSettingsClient: UserSettingsClient {
        get { self[UserSettingsClient.self] }
        set { self[UserSettingsClient.self] = newValue }
    }
}
