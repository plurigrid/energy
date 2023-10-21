import SwiftUI
import HeatKit

struct ChatView: View {
    @Environment(Store.self) private var store
    
    let chatID: String

    @State private var composerText = ""
    @State private var composerState: ChatComposerView.ViewState = .init()
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack {
                    ForEach(messages) { message in
                        ChatMessageContainerView(agent: agent, message: message)
                    }
                    if chat?.state == .processing {
                        ChatTypingIndicatorView(.leading)
                    }
                }
                .padding()
            }
        }
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            ChatComposerView(
                text: $composerText,
                state: composerState,
                submit: handleSubmitText,
                stop: handleCancel
            )
            .padding(.vertical, 8)
            .background(.background)
        }
        .onAppear {
            handleIntroduction()
        }
    }
    
    var agent: Agent? {
        guard let chat = store.get(chatID: chatID) else { return nil }
        return store.get(agentID: chat.agentID)
    }
    
    var chat: AgentChat? {
        store.get(chatID: chatID)
    }
    
    var messages: [Message] {
        guard let chat = store.get(chatID: chatID) else { return [] }
        return chat.messages.filter { $0.kind != .instruction }
    }
    
    func handleIntroduction() {
        guard let chat = store.get(chatID: chatID) else { return }
        guard chat.messages.isEmpty else { return }
        
        Task {
            let message = store.createMessage(kind: .instruction, role: .user, content: "Introduce yourself")
            try await ChatManager(store: store, chat: chat)
                .inject(message: message)
                .generateStream()
        }
    }
    
    func handleSubmitText(_ text: String) {
        guard let chat = store.get(chatID: chatID) else { return }
        
        Task {
            let message = store.createMessage(role: .user, content: text)
            try await ChatManager(store: store, chat: chat)
                .inject(message: message)
                .generateStream()
        }
    }
    
    func handleCancel() {
        print("not implemented")
    }
}
