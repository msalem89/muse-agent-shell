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
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                
                HStack {
                    TextField("Ask anything...", text: $viewModel.inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("Chat")
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
                        .padding(10)
                        .background(message.isUser ? Color.blue : Color(UIColor.secondarySystemBackground))
                        .foregroundColor(message.isUser ? .white : .primary)
                        .cornerRadius(12)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon(for: task.status))
                    .foregroundColor(color(for: task.status))
                Text(task.title)
                    .font(.headline)
            }
            Text(task.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(task.status.rawValue)
                .font(.caption)
                .padding(4)
                .background(color(for: task.status).opacity(0.2))
                .foregroundColor(color(for: task.status))
                .cornerRadius(4)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func icon(for status: TaskStatus) -> String {
        switch status {
        case .running: return "arrow.triangle.2.circlepath"
        case .needsApproval: return "exclamationmark.circle.fill"
        case .completed: return "checkmark.circle.fill"
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
