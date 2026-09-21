import Foundation

class BackendService {
    static let shared = BackendService()
    
    private init() {}
    
    var activeConnectionType: ConnectionProtocol = .ssh
    
    func connectSSH(host: String, port: String, user: String, pass: String, command: String) async throws {
        // In a real app, you would initialize an NMSSH session or SwiftSH here.
        self.activeConnectionType = .ssh
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func connectHTTPS(url: String, apiKey: String) async throws {
        // Standard URLSession setup
        self.activeConnectionType = .https
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func fetchChatHistory() async -> [ChatMessage] {
        return [
            ChatMessage(isUser: true, text: "Book a flight to New York.", associatedTask: nil),
            ChatMessage(
                isUser: false,
                text: "I am working on booking your flight to New York.",
                associatedTask: AgentTask(title: "Book Flight to NY", description: "Finding the best deals for tomorrow.", status: .running)
            ),
            ChatMessage(isUser: true, text: "Also, draft my weekly report.", associatedTask: nil),
            ChatMessage(
                isUser: false,
                text: "I've drafted the report. It requires your approval.",
                associatedTask: AgentTask(title: "Weekly Report", description: "Draft ready for your review.", status: .needsApproval)
            )
        ]
    }
    
    func fetchTasks() async -> [AgentTask] {
        return [
            AgentTask(title: "Book Flight to NY", description: "Finding the best deals for tomorrow.", status: .running),
            AgentTask(title: "Weekly Report", description: "Draft ready for your review.", status: .needsApproval),
            AgentTask(title: "Schedule Dentist", description: "Appointment confirmed for next Tuesday.", status: .completed)
        ]
    }
    
    func updatePrivacySettings(shareLocation: Bool, shareContacts: Bool) async {
        // Mock updating settings on backend
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}
