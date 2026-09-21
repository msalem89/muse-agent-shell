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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic Pastel Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark 
                                       ? [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.05, green: 0.15, blue: 0.2)] 
                                       : [Color(red: 0.95, green: 0.9, blue: 1.0), Color(red: 0.85, green: 0.95, blue: 1.0)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                            }
                        }
                        .padding()
                    }
                    
                    // Chat Input Area
                    HStack {
                        TextField("Message Agent...", text: $viewModel.inputText)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                        
                        Button(action: {
                            viewModel.sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Agent Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear {
                viewModel.loadMessages()
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                if let text = message.text {
                    Text(text)
                        .padding(14)
                        .background(message.isUser ? AnyView(Color.blue.opacity(0.8)) : AnyView(Rectangle().fill(.ultraThinMaterial)))
                        .foregroundColor(message.isUser ? .white : .primary)
                        .cornerRadius(18)
                        // Add slight shadow for depth
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                if let task = message.associatedTask {
                    TaskCard(task: task)
                }
            }
            
            if !message.isUser { Spacer() }
        }
    }
}

struct TaskCard: View {
    let task: AgentTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon(for: task.status))
                    .foregroundColor(color(for: task.status))
                    .font(.title3)
                Text(task.title)
                    .font(.headline)
            }
            Text(task.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
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
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        // Add a subtle border to enhance the glass effect
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
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
        case .running: return .blue
        case .needsApproval: return .orange
        case .completed: return .green
        }
    }
}
