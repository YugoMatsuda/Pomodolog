import ComposableArchitecture
import SwiftUI

@Reducer
struct RootPage {
    @ObservableState
    struct State: Equatable {
        var selectionPage: SelectionPage? = .home

        enum SelectionPage: Int, Equatable,Hashable, CaseIterable {
            case setting
            case home
            case hilight
        }
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

struct RootPageView: View {
    @Bindable var store: StoreOf<RootPage>
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal) {
                HStack {
                    ForEach(RootPage.State.SelectionPage.allCases, id: \.self) { page in
                        switch page {
                        case .setting:
                            Button("Setting") {
                            }
                            .id(page)
                        case .home:
                            Text("home")
                                .id(page)

                        case .hilight:
                            Button("Hilight") {
                            }
                            .id(page)
                        }
                    }
                    .containerRelativeFrame([.horizontal, .vertical], count: 1, spacing: 0)
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $store.selectionPage)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.never)
            .defaultScrollAnchor(.center)
        }
    }
}

#Preview {
    RootPageView(store: .init(initialState: RootPage.State(), reducer: {
        RootPage()
    }))
}