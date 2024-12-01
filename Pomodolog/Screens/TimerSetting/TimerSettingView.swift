import CasePaths
import ComposableArchitecture
import SwiftUI

@Reducer
struct TimerSettingReducer {
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        @Shared var timerSetting: TimerSetting
        var displayResult: DisplayResult = .loading
        
        enum DisplayResult: Equatable {
            case success([Tag])
            case failure
            case loading

        }
    }
    
    enum Action: BindableAction {
        case view(ViewAction)
        case delegate(DelegateAction)
        case binding(BindingAction<State>)
        case `internal`(InternalAction)
        case destination(PresentationAction<Destination.Action>)

        enum ViewAction: Equatable {
            case onLoad
            case didTapTag(Tag)
            case didTapAddTagButton
        }
        
        enum DelegateAction: Equatable {
        }
        
        enum InternalAction {
            case observeResponse(TaskResult<[Tag]>)
        }
    }
    
    @Dependency(\.coreDataClient) var coreDataClient

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .view(.onLoad):
                return  .run { send in
                    let initialFetch = try await fetchEntity()
                    await send(.internal(.observeResponse(.success(initialFetch))), animation: .default)
                    let observeRemoteChange = coreDataClient.observeRemoteChange()
                    for try await _ in observeRemoteChange._throttle(for: .seconds(0.5), latest: true) {
                        AppLogger.shared.log("reload hilight", .debug)
                        let entity = try await fetchEntity()
                        await send(.internal(.observeResponse(.success(entity))), animation: .default)
                    }
                } catch: { error, send in
                    await send(.internal(.observeResponse(.failure(error))))
                }
            case .view(.didTapTag(let tag)):
                state.timerSetting.currentTag = tag
                return .run { [state] _ in
                    try await coreDataClient.insert(state.timerSetting)
                }
            case .view(.didTapAddTagButton):
                guard case let .success(tags) = state.displayResult else { return .none }
                state.destination = .tagFormView(TagForm.State.init(mode: .add(sort: tags.count)))
                return .none
            case let .internal(.observeResponse(.success(resp))):
                state.displayResult = .success(resp)
                return .none
            case let .internal(.observeResponse(.failure(error))):
                AppLogger.shared.log("observeResponse error: \(error)", .crit)
                state.displayResult = .failure
                return .none
            case .internal:
                return .none
            case .binding(\.timerSetting):
                return .run { [state] _ in
                    try await coreDataClient.insert(state.timerSetting)
                }
            case .destination(.presented(.tagFormView(.delegate(.didSucceedSaveTag)))):
                state.destination = nil
                return .none
            case .binding:
                return .none
            case .delegate:
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
    private func fetchEntity() async throws -> [Tag] {
        try await coreDataClient.fetchAll(
            Tag.self,
            sortDescriptors: [SortDescriptorData(key: "sort", ascending: true)]
        )
    }
}


extension TimerSettingReducer {
    @Reducer(state: .equatable)
    enum Destination {
        case tagFormView(TagForm)
    }
}


struct TimerSettingView: View {
    @Bindable var store: StoreOf<TimerSettingReducer>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch store.displayResult {
                case .success(let tags):
                    Form {
                        Section("Timer") {
                            Picker("Mode", selection: $store.timerSetting.timerType) {
                                ForEach(TimerSetting.TimerType.allCases, id: \.self) {
                                    Text($0.title).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Session Time", selection: $store.timerSetting.sessionTimeMinutes) {
                                ForEach(1...60, id: \.self) { minute in
                                    Text("\(minute) min").tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Break Time", selection: $store.timerSetting.shortBreakTimeMinutes) {
                                ForEach(1...30, id: \.self) { minute in
                                    Text("\(minute) min").tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Section("BGM") {
                            Picker("BGM", selection: $store.timerSetting.backgroundMusicType) {
                                ForEach(BackgroundMusicType.allCases, id: \.self) {
                                    Text($0.title).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Section("Tags") {
                            ForEach(tags) { tag in
                                let tagId = tag.id
                                let isSelectedTag = tagId == store.timerSetting.currentTag?.id
                                Button {
                                    store.send(.view(.didTapTag(tag)))
                                } label: {
                                    HStack {
                                        TagItemView(tag: tag)
                                        Spacer()
                                        if isSelectedTag {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                                .font(.headline)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Button(action: {
                                store.send(.view(.didTapAddTagButton))
                            }, label: {
                                HStack {
                                    Spacer()
                                    Text("Add Tag")
                                }
                                .contentShape(Rectangle())
                            })
                            .sheet(
                                item: $store.scope(
                                    state: \.destination?.tagFormView,
                                    action: \.destination.tagFormView
                                )
                            ) { store in
                                NavigationStack {
                                    TagFormView(store: store)
                                }
                            }
                        }
                        
                    }
                case .failure:
                    Text("Failed to load tags")
                    
                case .loading:
                    ProgressView()
                }
            }
            .navigationTitle("Timer Setting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onLoad {
                store.send(.view(.onLoad))
            }
        }
    }
}

#Preview {
    TimerSettingView(store: .init(initialState: TimerSettingReducer.State.init(
        timerSetting: Shared(TimerSetting.initial())
    ), reducer: {
        TimerSettingReducer()
    }))
}
