import SwiftUI

enum ConnectionProtocol: String, CaseIterable, Identifiable {
    case hosted = "Hosted (Cloud)"
    case https = "HTTPS (REST)"
    case websocket = "WebSocket (WSS)"
    case ssh = "SSH (CLI)"
    var id: Self { self }
}

@MainActor
class ConnectionViewModel: ObservableObject {
    @Published var connectionProtocol: ConnectionProtocol = .ssh
    
    // Web/API Fields (HTTPS & WebSocket)
    @Published var backendURL: String = ""
    @Published var apiKey: String = ""
    
    // SSH Fields
    @Published var sshHost: String = ""
    @Published var sshPort: String = "22"
    @Published var sshUsername: String = ""
    @Published var sshPassword: String = ""
    @Published var sshKeyPath: String = "" // For robust private key auth
    @Published var sshCommand: String = "python nafs/run_qarin.py"
    
    @Published var isConnecting: Bool = false
    
    func connect(completion: @escaping () -> Void) {
        isConnecting = true
        Task {
            do {
                switch connectionProtocol {
                case .ssh:
                    try await BackendService.shared.connectSSH(host: sshHost, port: sshPort, user: sshUsername, pass: sshPassword, keyPath: sshKeyPath, command: sshCommand)
                case .https:
                    try await BackendService.shared.connectHTTPS(url: backendURL, apiKey: apiKey)
                case .websocket:
                    try await BackendService.shared.connectWebSocket(url: backendURL, apiKey: apiKey)
                case .hosted:
                    try await BackendService.shared.connectHosted(apiKey: apiKey)
                }
                isConnecting = false
                completion()
            } catch {
                isConnecting = false
            }
        }
    }
}

struct ConnectionView: View {
    @StateObject private var viewModel = ConnectionViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Connection Protocol")) {
                    Picker("Method", selection: $viewModel.connectionProtocol) {
                        ForEach(ConnectionProtocol.allCases) { protocolType in
                            Text(protocolType.rawValue).tag(protocolType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if viewModel.connectionProtocol == .hosted {
                    Section(header: Text("Hosted Configuration")) {
                        Text("Connect to our secure, managed cloud agent. No setup required.")
                            .font(.footnote).foregroundColor(.gray)
                        SecureField("API Key or License Code (Optional)", text: $viewModel.apiKey)
                    }
                } else if viewModel.connectionProtocol == .https || viewModel.connectionProtocol == .websocket {
                    Section(header: Text("\(viewModel.connectionProtocol == .https ? "HTTPS" : "WebSocket") Configuration")) {
                        TextField("Backend URL (e.g. \(viewModel.connectionProtocol == .https ? "http" : "ws")://192.168.1.5:8000)", text: $viewModel.backendURL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                        SecureField("API Key (Optional)", text: $viewModel.apiKey)
                    }
                } else {
                    Section(header: Text("SSH Configuration")) {
                        TextField("Host (IP or Tailscale Node)", text: $viewModel.sshHost)
                            .keyboardType(.numbersAndPunctuation)
                            .autocapitalization(.none)
                        TextField("Port", text: $viewModel.sshPort)
                            .keyboardType(.numberPad)
                        TextField("Username", text: $viewModel.sshUsername)
                            .autocapitalization(.none)
                        SecureField("Password (or leave blank for Key)", text: $viewModel.sshPassword)
                        TextField("Private Key File Name (e.g. id_ed25519)", text: $viewModel.sshKeyPath)
                            .autocapitalization(.none)
                    }
                    Section(header: Text("Agent Command Context")) {
                        TextField("CLI Command (e.g. run_qarin.sh)", text: $viewModel.sshCommand)
                            .autocapitalization(.none)
                    }
                }
                
                Button(action: {
                    viewModel.connect { appState.isConnected = true }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isConnecting { ProgressView().progressViewStyle(CircularProgressViewStyle()) }
                        else { Text("Connect to Agent System").fontWeight(.semibold) }
                        Spacer()
                    }
                }
                .disabled(viewModel.isConnecting)
            }
            .navigationTitle("Agent Connection")
        }
    }
}

