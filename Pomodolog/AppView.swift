import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var appDelegate: AppDelegateReducer.State
        var rootAppState: RootAppState
        @CasePathable
        @dynamicMemberLookup
        public enum RootAppState: Equatable {
            case initial
            case splash(Splash.State)
            case rootPage(RootPage.State)
        }
    }

    enum Action {
        case appDelegate(AppDelegateReducer.Action)
        case rootPage(RootPage.Action)
        case splash(Splash.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.appDelegate, action: \.appDelegate) {
            AppDelegateReducer()
        }
        Scope(state: \.rootAppState, action: \.self) {
          Scope(state: \.rootPage, action: \.rootPage) {
              RootPage()
          }
            Scope(state: \.splash, action: \.splash) {
                Splash()
            }
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .appDelegate(.didFinishLaunching):
                state.rootAppState = .splash(Splash.State.init())
                return .none
            case .splash(.delegate(.didCompleteLaunch(let timerSetting))):
                state.rootAppState = .rootPage(
                    RootPage.State.init(
                        timerSettnig: Shared(timerSetting)
                    )
                )
                return .none
            case .splash:
                return .none
            case .rootPage:
                return .none
            }
        }
    }
}

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    var body: some View {
        Group {
            switch store.rootAppState {
            case .initial:
                ProgressView()
            case .splash:
                if let store = store.scope(state: \.rootAppState.splash, action: \.splash) {
                    SplashView(store: store)
                }
            case .rootPage:
                if let store = store.scope(state: \.rootAppState.rootPage, action: \.rootPage) {
                    RootPageView(store: store)
                }
            }
        }
    }
}

#Preview {
    AppView(store: .init(initialState: AppFeature.State.init(
        appDelegate: AppDelegateReducer.State.init(),
        rootAppState: .initial
    )) {
        AppFeature()
    })
}
