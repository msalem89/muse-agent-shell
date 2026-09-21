import Foundation

import Citadel
import NIOSSH
import NIO

class BackendService {
    static let shared = BackendService()
    
    private init() {}
    
    var activeConnectionType: ConnectionProtocol = .ssh
    var sshClient: SSHClient?
    
    // Simulating a dynamic theme payload sent by the backend node (e.g. Qarin)
    private let mockBackendTheme = ThemeConfig(
        brandName: "Qarin OS",
        primaryHex: "#2ECC71", // Matrix/Terminal Green
        secondaryHex: "#1F2937", // Dark Gray
        useGlassmorphism: false,
        isTerminalStyle: true
    )
    
    func connectSSH(host: String, port: String, user: String, pass: String, keyPath: String, command: String) async throws -> ThemeConfig {
        self.activeConnectionType = .ssh
        let portInt = Int(port) ?? 22
        
        let authMethod: NIOSSH.SSHAuthenticationMethod
        if !keyPath.isEmpty {
            authMethod = .password("Requires Key Loading Implementation") 
        } else {
            authMethod = .password(pass)
        }
        
        let client = try await SSHClient.connect(
            host: host,
            port: portInt,
            authenticationMethod: authMethod,
            hostKeyValidator: .acceptAnything(),
            reconnect: .never
        )
        self.sshClient = client
        return mockBackendTheme // In real app, run a command to fetch JSON config
    }
    
    func connectWebSocket(url: String, apiKey: String) async throws -> ThemeConfig {
        guard let endpoint = URL(string: url) else { throw URLError(.badURL) }
        var request = URLRequest(url: endpoint)
        if !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        self.activeConnectionType = .websocket
        return ThemeConfig.defaultTheme
    }
    
    func connectHTTPS(url: String, apiKey: String) async throws -> ThemeConfig {
        guard let endpoint = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        if !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        self.activeConnectionType = .https
        return ThemeConfig.defaultTheme
    }
    
    func connectHosted(apiKey: String) async throws -> ThemeConfig {
        self.activeConnectionType = .hosted
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return ThemeConfig.defaultTheme
    }
    
    func sendMessage(text: String, sshCommandTemplate: String = "python nafs/run_qarin.py") async throws -> String {
        // Fetch real-time device context
        let deviceContext = DeviceManager.shared.buildDeviceContextPayload()
        let contextJsonData = try? JSONSerialization.data(withJSONObject: deviceContext)
        let contextString = String(data: contextJsonData ?? Data(), encoding: .utf8) ?? "{}"
        
        switch activeConnectionType {
        case .ssh:
            guard let sshClient = self.sshClient else {
                throw URLError(.notConnectedToInternet)
            }
            // Execute the command remotely. We format the command with the prompt.
            // Example: `python nafs/run_qarin.py "my message"`
            let escapedPrompt = text.replacingOccurrences(of: "\"", with: "\\\"")
            let escapedContext = contextString.replacingOccurrences(of: "\"", with: "\\\"")
            let fullCommand = "\(sshCommandTemplate) \"\(escapedPrompt)\" --device-context \"\(escapedContext)\""
            
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
            
            // Bundle context in REST payload
            let payload: [String: Any] = ["prompt": text, "deviceContext": deviceContext]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            if let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
                return decoded["response"] ?? "Success"
            }
            return String(data: data, encoding: .utf8) ?? "Success"
            
        case .websocket:
            // Placeholder for WebSocket messaging
            return "WebSocket implementation pending real-time event streaming."
            
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
