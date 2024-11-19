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
            case root
        }
    }

    enum Action {
        case appDelegate(AppDelegateReducer.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.appDelegate, action: \.appDelegate) {
            AppDelegateReducer()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .appDelegate(.didFinishLaunching):
                state.rootAppState = .root
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
            case .root:
                Text("Rootview")
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
