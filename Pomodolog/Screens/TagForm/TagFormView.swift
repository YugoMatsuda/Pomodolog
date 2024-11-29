import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct TagForm {
    @ObservableState
    struct State: Equatable {
        let mode: Mode
        var tag: Tag
        var selectedColor: Color
        var name: String
        
        var isDisableSaveButton: Bool {
            name.isEmpty
        }
        
        init(mode: Mode) {
            let defaulut: Color = .blue
            self.mode = mode
            switch mode {
            case let .add(sort):
                selectedColor = defaulut
                name = ""
                self.tag = Tag(
                    id: UUID().uuidString,
                    name: "",
                    colorHex: defaulut.toHex() ?? "",
                    sort: sort,
                    sessionIds: [],
                    createAt: .now,
                    updateAt: .now
                )
            case let .edit(tag):
                self.tag = tag
                selectedColor = .init(hex: tag.colorHex) ?? defaulut
                name = tag.name
            }
        }
        
        enum Mode: Equatable {
            case add(sort: Int)
            case edit(Tag)
        }
    }
    
    enum Action: BindableAction {
        case view(ViewAction)
        case delegate(DelegateAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)

        enum ViewAction: Equatable {
            case didTapSaveButton
        }
        
        enum DelegateAction: Equatable {
            case didSucceedSaveTag
        }
        
        enum InternalAction {
            case inserrTag(TaskResult<VoidSuccess>)
        }
    }
    
    @Dependency(\.coreDataClient) var coreDataClient
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view(.didTapSaveButton):
                return .run { [state] send in
                    await send(
                        .internal(
                            .inserrTag(
                                await TaskResult {
                                    try await coreDataClient.insert(state.tag)
                                }
                            )
                        )
                    )
                }
            case .binding(\.selectedColor):
                state.tag.colorHex = state.selectedColor.toHex() ?? ""
                return .none
            case .binding(\.name):
                state.tag.name = state.name
                return .none
            case .internal(.inserrTag(.success)):
                return .send(.delegate(.didSucceedSaveTag))
            case let .internal(.inserrTag(.failure(error))):
                AppLogger.shared.log("insertTag Error: \(error)", .crit)
                return .none
            case .binding:
                return .none
            case .delegate:
              return .none
            }
        }
    }
}

struct TagFormView: View {
    @Bindable var store: StoreOf<TagForm>
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Form {
            HStack {
                Text("Title")
                TextField("", text: $store.name)
                    .multilineTextAlignment(TextAlignment.trailing)
            }
            ColorPicker("Color", selection: $store.selectedColor, supportsOpacity: false)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    store.send(.view(.didTapSaveButton))
                }) {
                    Text("Save")
                }
                .disabled(store.isDisableSaveButton)
            }
        }
    }
}


#Preview {
    TagFormView(
        store: Store(
            initialState: TagForm.State(mode: .add(sort: 0)),
            reducer: {
                TagForm()
            }
        )
    )
}
