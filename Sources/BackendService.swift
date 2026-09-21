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
    
    func connectHosted(apiKey: String) async throws {
        // Points to our official cloud hosted agent (future)
        self.activeConnectionType = .hosted
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func sendMessage(text: String, sshCommandTemplate: String = "python nafs/run_qarin.py") async throws -> String {
        switch activeConnectionType {
        case .ssh:
            guard let sshClient = self.sshClient else {
                throw URLError(.notConnectedToInternet)
            }
            // Execute the command remotely. We format the command with the prompt.
            // Example: `python nafs/run_qarin.py "my message"`
            let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
            let fullCommand = "\(sshCommandTemplate) \"\(escapedText)\""
            
            // Note: Exact Citadel syntax for executing commands
            let responseBuffer = try await sshClient.executeCommand(fullCommand)
            var buffer = responseBuffer
            let responseString = buffer.readString(length: buffer.readableBytes) ?? ""
            return responseString.trimmingCharacters(in: .whitespacesAndNewlines)
            
        case .https:
            // HTTPS POST request to local Agent Orchestrator
            guard let endpoint = URL(string: "http://localhost:8000/chat") else { throw URLError(.badURL) }
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = ["prompt": text]
            request.httpBody = try? JSONEncoder().encode(body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            if let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
                return decoded["response"] ?? "Success"
            }
            return String(data: data, encoding: .utf8) ?? "Success"
            
        case .hosted:
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return "This is a response from the Hosted cloud agent."
        }
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
