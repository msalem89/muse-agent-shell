import Foundation

import Citadel
import NIOSSH
import NIO

class BackendService {
    static let shared = BackendService()
    
    private init() {}
    
    var activeConnectionType: ConnectionProtocol = .ssh
    var sshClient: SSHClient?
    
    func connectSSH(host: String, port: String, user: String, pass: String, command: String) async throws {
        self.activeConnectionType = .ssh
        
        let portInt = Int(port) ?? 22
        
        // Initialize Citadel SSH Client
        let client = try await SSHClient.connect(
            host: host,
            port: portInt,
            authenticationMethod: .password(pass),
            hostKeyValidator: .acceptAnything(),
            reconnect: .never
        )
        self.sshClient = client
    }
    
    func connectHTTPS(url: String, apiKey: String) async throws {
        guard let endpoint = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        if !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Simple ping to verify connection
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        self.activeConnectionType = .https
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
