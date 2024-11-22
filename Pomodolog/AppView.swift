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
            case rootPage(RootPage.State)
        }
    }

    enum Action {
        case appDelegate(AppDelegateReducer.Action)
        case rootPage(RootPage.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.appDelegate, action: \.appDelegate) {
            AppDelegateReducer()
        }
        Scope(state: \.rootAppState, action: \.self) {
          Scope(state: \.rootPage, action: \.rootPage) {
              RootPage()
          }
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .appDelegate(.didFinishLaunching):
                state.rootAppState = .rootPage(RootPage.State.init())
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
