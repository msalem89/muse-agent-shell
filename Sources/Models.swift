import Foundation

enum TaskStatus: String, CaseIterable {
    case running = "Running"
    case needsApproval = "Needs Approval"
    case completed = "Completed"
}

struct AgentTask: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    var status: TaskStatus
}

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let isUser: Bool
    let text: String?
    let associatedTask: AgentTask?
}
