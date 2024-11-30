import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct SpeachContent {
    @ObservableState
    struct State: Equatable {
        var displayResult: DisplayResult
        
        init(displayResult: DisplayResult) {
            self.displayResult = displayResult
        }
        
        enum DisplayResult: Equatable {
            case success(String)
            case failure
            case loading
        }
    }
    
    enum Action: BindableAction {
        case view(ViewAction)
        case delegate(DelegateAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)

        enum ViewAction: Equatable {
            case onLoad
        }
        
        enum DelegateAction: Equatable {
        }
        
        enum InternalAction {
        }
    }
    
    @Dependency(\.coreDataClient) var coreDataClient

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view(.onLoad):
                return .none
            case .internal:
                return .none
            case .binding:
                return .none
            case .delegate:
              return .none
            }
        }
    }
}

struct SpeachContentView: View {
    @Bindable var store: StoreOf<SpeachContent>

    var body: some View {
        switch store.displayResult {
        case .success(let text):
            Text(text)
        case .failure:
            Text("Failed to genrerate words.")
        case .loading:
            ProgressView()
        }
    }
}

#Preview {
    SpeachContentView(store: .init(initialState: SpeachContent.State.init(displayResult: .loading), reducer: {
        SpeachContent()
    }))
}
