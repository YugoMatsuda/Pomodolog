import ComposableArchitecture
import SwiftUI

@Reducer
struct Home {
    @ObservableState
    struct State: Equatable {
        @Shared var timerSetting: TimerSetting
    }

    enum Action: BindableAction {
        case view(ViewAction)
        case binding(BindingAction<State>)

        enum ViewAction {
            case onAppear
        }
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .none
            case .binding:
                return .none
            }
        }
    }
}

struct HomeView: View {
    @Bindable var store: StoreOf<Home>

    var body: some View {
        VStack{
            TimerRingView()
        }
    }
}

#Preview {
    HomeView(store: .init(initialState: Home.State.init(
        timerSetting: Shared(TimerSetting.initial())
    ), reducer: {
        Home()
    }))
}
