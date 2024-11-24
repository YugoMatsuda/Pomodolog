import SwiftUI
import ComposableArchitecture

@Reducer
struct AppDelegateReducer {
    struct State: Equatable {
        public init() {}
    }
    
    enum Action: Equatable {
        case didFinishLaunching
    }
    
    init() {}
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {
    let store = Store(initialState: AppFeature.State.init(
        appDelegate: AppDelegateReducer.State.init(),
        rootAppState: .initial
    )) {
        AppFeature()
            ._printChanges()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        let _ = KeychainHelper.keychain
        let _ = CoreDataManager.shared
        store.send(.appDelegate(.didFinishLaunching), animation: .easeIn)
        return true
    }
}
