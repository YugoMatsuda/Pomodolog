import Dependencies
import DependenciesMacros
import Foundation

extension DependencyValues {
  var userDefaults: UserDefaultsClient {
    get { self[UserDefaultsClient.self] }
    set { self[UserDefaultsClient.self] = newValue }
  }
}

extension UserDefaultsClient: DependencyKey {
static let liveValue: Self = {
    let defaults: @Sendable () -> UserDefaults = {
        return UserDefaults.standard
    }
    return Self(
      boolForKey: { defaults().bool(forKey: $0) },
      dataForKey: { defaults().data(forKey: $0) },
      doubleForKey: { defaults().double(forKey: $0) },
      integerForKey: { defaults().integer(forKey: $0) },
      dateForKey: { defaults().object(forKey: $0) as? Date },
      remove: { defaults().removeObject(forKey: $0) },
      setBool: { defaults().set($0, forKey: $1) },
      setData: { defaults().set($0, forKey: $1) },
      setDouble: { defaults().set($0, forKey: $1) },
      setInteger: { defaults().set($0, forKey: $1) },
      setDate: { defaults().set($0, forKey: $1) }
    )
  }()
}

@DependencyClient
struct UserDefaultsClient {
    var boolForKey: @Sendable (String) -> Bool? = { _ in nil }
    var dataForKey: @Sendable (String) -> Data?
    var doubleForKey: @Sendable (String) -> Double = { _ in 0 }
    var integerForKey: @Sendable (String) -> Int = { _ in 0 }
    var dateForKey: @Sendable (String) -> Date?
    var remove: @Sendable (String) async -> Void
    var setBool: @Sendable (Bool, String) async -> Void
    var setData: @Sendable (Data?, String) async -> Void
    var setDouble: @Sendable (Double, String) async -> Void
    var setInteger: @Sendable (Int, String) async -> Void
    var setDate: @Sendable (Date, String) async -> Void
    
    var isOnBackGroundMusicSound: Bool {
        return self.boolForKey(CommonKey.isOnBackGroundMusicSound.rawValue) ?? true
    }
    
    func setIsOnBackGroundMusicSound(_ bool: Bool) async {
        await self.setBool(bool, CommonKey.isOnBackGroundMusicSound.rawValue)
    }
    
    var isOnAIVoiceSound: Bool {
        return self.boolForKey(CommonKey.isOnAIVoiceSound.rawValue) ?? true
    }
    
    func setIsOnAIVoiceSound(_ bool: Bool) async {
        await self.setBool(bool, CommonKey.isOnAIVoiceSound.rawValue)
    }
}

enum CommonKey: String {
    case isOnBackGroundMusicSound = "isOnBackGroundMusicSound"
    case isOnAIVoiceSound = "isOnAIVoiceSound"
}
