import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    
    func loadMessages() {
        Task {
            let fetchedMessages = await BackendService.shared.fetchChatHistory()
            self.messages = fetchedMessages
        }
    }
    
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        let userMessage = inputText
        let newMessage = ChatMessage(isUser: true, text: userMessage, associatedTask: nil)
        messages.append(newMessage)
        inputText = ""
        
        Task {
            do {
                let responseText = try await BackendService.shared.sendMessage(text: userMessage)
                let reply = ChatMessage(isUser: false, text: responseText, associatedTask: nil)
                messages.append(reply)
            } catch {
                let errorReply = ChatMessage(isUser: false, text: "Error: \(error.localizedDescription)", associatedTask: nil)
                messages.append(errorReply)
            }
        }
    }
}

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let theme = appState.currentTheme
        NavigationView {
            ZStack {
                // Dynamic AI Background
                if theme.isTerminalStyle {
                    Color.black.ignoresSafeArea()
                } else if theme.useGlassmorphism {
                    LinearGradient(
                        gradient: Gradient(colors: colorScheme == .dark 
                                           ? [Color(hex: theme.secondaryHex).opacity(0.8), Color.black] 
                                           : [Color(hex: theme.primaryHex).opacity(0.1), Color(hex: theme.secondaryHex).opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ).ignoresSafeArea()
                } else {
                    Color(UIColor.systemBackground).ignoresSafeArea()
                }
                
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message, theme: theme)
                            }
                        }
                        .padding()
                    }
                    
                    // Chat Input Area
                    HStack {
                        TextField("Message \(theme.brandName)...", text: $viewModel.inputText)
                            .padding(12)
                            .background(theme.useGlassmorphism ? AnyView(Rectangle().fill(.ultraThinMaterial)) : AnyView(Color(UIColor.secondarySystemBackground)))
                            .cornerRadius(20)
                            .foregroundColor(theme.isTerminalStyle ? Color(hex: theme.primaryHex) : .primary)
                        
                        Button(action: {
                            viewModel.sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(Color(hex: theme.primaryHex))
                        }
                    }
                    .padding()
                    .background(theme.useGlassmorphism ? AnyView(Rectangle().fill(.ultraThinMaterial)) : AnyView(Color(UIColor.systemBackground)))
                }
            }
            .navigationTitle(theme.brandName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.useGlassmorphism ? .ultraThinMaterial : .visible, for: .navigationBar)
            .onAppear {
                viewModel.loadMessages()
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let theme: ThemeConfig
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                if let text = message.text {
                    Text(text)
                        .padding(14)
                        .background(
                            message.isUser 
                            ? AnyView(Color(hex: theme.primaryHex).opacity(0.8)) 
                            : (theme.useGlassmorphism ? AnyView(Rectangle().fill(.ultraThinMaterial)) : AnyView(Color(UIColor.secondarySystemBackground)))
                        )
                        .foregroundColor(message.isUser ? .white : (theme.isTerminalStyle ? Color(hex: theme.primaryHex) : .primary))
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .font(theme.isTerminalStyle ? .system(.body, design: .monospaced) : .body)
                }
                
                if let task = message.associatedTask {
                    TaskCard(task: task, theme: theme)
                }
            }
            
            if !message.isUser { Spacer() }
        }
    }
}

struct TaskCard: View {
    let task: AgentTask
    let theme: ThemeConfig
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon(for: task.status))
                    .foregroundColor(color(for: task.status))
                    .font(.title3)
                Text(task.title)
                    .font(theme.isTerminalStyle ? .system(.headline, design: .monospaced) : .headline)
                    .foregroundColor(theme.isTerminalStyle ? Color(hex: theme.primaryHex) : .primary)
            }
            Text(task.description)
                .font(theme.isTerminalStyle ? .system(.subheadline, design: .monospaced) : .subheadline)
                .foregroundColor(theme.isTerminalStyle ? Color(hex: theme.secondaryHex) : .secondary)
            
            HStack {
                Text(task.status.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color(for: task.status).opacity(0.2))
                    .foregroundColor(color(for: task.status))
                    .cornerRadius(8)
                Spacer()
                if task.status == .running {
                    ProgressView()
                }
            }
        }
        .padding(16)
        .background(theme.useGlassmorphism ? AnyView(Rectangle().fill(.ultraThinMaterial)) : AnyView(Color(UIColor.secondarySystemBackground)))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.useGlassmorphism ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
    
    private func icon(for status: TaskStatus) -> String {
        switch status {
        case .running: return "gearshape.2.fill"
        case .needsApproval: return "exclamationmark.shield.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }
    
    private func color(for status: TaskStatus) -> Color {
        switch status {
        case .running: return Color(hex: theme.primaryHex)
        case .needsApproval: return .orange
        case .completed: return .green
        }
    }
}
