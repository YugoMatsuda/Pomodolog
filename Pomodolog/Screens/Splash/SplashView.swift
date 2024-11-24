import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct Splash {
    @ObservableState
    struct State: Equatable {
        var splashState: SplashState = .initial

        enum SplashState: Equatable {
            case initial
            case setupDefalutData
            case failedLaunch(FailedLaunchError)
            
            var displayText: String {
                switch self {
                case .initial:
                   #if DEBUG
                   return "Initial"
                   #else
                   return ""
                   #endif
                case .setupDefalutData:
                    #if DEBUG
                    return String(localized: "Setting up the initial configuration, \n please wait...")
                    #else
                    return String(localized: "Setting up the initial configuration, \n please wait...")
                    #endif
                case .failedLaunch(_):
                    return ""
                }
            }
            
            enum FailedLaunchError: Equatable {
                case unreadKechain
                case applicationFatal
            }
        }
    }
    
    enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)

        enum ViewAction: Equatable {
            case task
        }
        
        enum DelegateAction: Equatable {
            case didCompleteLaunch(TimerSetting)
        }
        
        enum InternalAction {
            case exeSetupDefaultData
            case receiveTimerSetting(TimerSetting)
            case occuredSetupDefaultDataError(SetupDefaultDataError)
            
            enum SetupDefaultDataError: Error {
                case failedSetupDefaultData(Error)
                case failedReadKeychain(Error)
            }
        }
    }
    
    @Dependency(\.coreDataClient) var coreDataClient
    @Dependency(\.userSettingsClient) var userSettingsClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                do {
                    let userId = try userSettingsClient.getUserId()
                    let isFirstLaunch = userId == nil
                    if isFirstLaunch {
                        return .send(.internal(.exeSetupDefaultData), animation: .easeIn)
                    }
                    return .run { send in
                        let timerSetting = try await coreDataClient.fetchById(TimerSetting.self, id: TimerSetting.id()) ?? .initial()
                        await send(.internal(.receiveTimerSetting(timerSetting)))
                    }
                } catch {
                    return .send(
                        .internal(
                            .occuredSetupDefaultDataError(.failedReadKeychain(error))),
                        animation: .easeIn
                    )
                }
            case .internal(.exeSetupDefaultData):
                state.splashState = .setupDefalutData
                return .run { send in
                    // UserIdの生成
                    let userId = UUID().uuidString
                    try await userSettingsClient.saveUserId(userId)
                    
                    // 初期タグの保存
                    let defaultTags = Tag.defaultTags()
                    for tag in defaultTags {
                        try await coreDataClient.insert(tag)
                    }
                    
                    // 初期タイマー設定の保存
                    let timerSetting = TimerSetting.initial()
                    try await coreDataClient.insert(timerSetting)
                    await send(.internal(.receiveTimerSetting(timerSetting)))
                    
                } catch: { error, send in
                    await send(
                        .internal(
                            .occuredSetupDefaultDataError(.failedSetupDefaultData(error))),
                        animation: .easeIn
                    )
                }
            case .internal(.receiveTimerSetting(let timerSetting)):
                return .send(.delegate(.didCompleteLaunch(timerSetting)), animation: .easeIn)
            case .internal(.occuredSetupDefaultDataError(let error)):
                switch error {
                case .failedReadKeychain(let error):
                    state.splashState = .failedLaunch(.unreadKechain)
                    AppLogger.shared.log("failedReadKeychain: \(error)", .warn)
                case .failedSetupDefaultData(let error):
                    state.splashState = .failedLaunch(.applicationFatal)
                    AppLogger.shared.log("failedSetupDefaultData: \(error)", .warn)
                }
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
struct SplashView: View {
    @Bindable var store: StoreOf<Splash>

    var body: some View {
        Group {
            switch store.splashState {
            case .initial, .setupDefalutData:
                VStack(alignment: .center) {
                    Text(store.splashState.displayText)
                        .padding(.horizontal)
                    ProgressView()
                }
            case let .failedLaunch(error):
                switch error {
                case .unreadKechain:
                    ContentUnavailableView(
                        "Recover issue",
                        systemImage: "person.badge.key",
                        description: Text("Failed to restore user data.")
                    )
                case .applicationFatal:
                    ContentUnavailableView(
                        "Connection issue",
                        systemImage: "wifi.slash",
                        description: Text("Failed to set up the initial data. Please restart in an area with a stable network connection.")
                    )
                }
            }
        }
        .task {
            await store.send(.view(.task)).finish()
        }
    }
}

#Preview {
    SplashView(store: .init(initialState: Splash.State.init(), reducer: {
        Splash()
    }))
}
