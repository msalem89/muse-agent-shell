import SwiftUI

    var id: Self { self }
}

@MainActor
class ConnectionViewModel: ObservableObject {
    @Published var connectionProtocol: ConnectionProtocol = .gemini
    
    // SSH Config
    @Published var sshHost = ""
    @Published var sshPort = "22"
    @Published var sshUsername = ""
    @Published var sshPassword = ""
    @Published var sshKeyPath = ""
    @Published var sshCommand = "python nafs/run_qarin.py"
    
    // HTTPS/WSS Config
    @Published var backendURL = ""
    
    // Global API Key (Used for Hosted, HTTPS, or Cloud LLMs)
    @Published var apiKey = ""
    
    @Published var isConnecting: Bool = false
    
    func connect(appState: AppState, completion: @escaping () -> Void) {
        isConnecting = true
        Task {
            do {
                let fetchedTheme: ThemeConfig
                switch connectionProtocol {
                case .ssh:
                    fetchedTheme = try await BackendService.shared.connectSSH(host: sshHost, port: sshPort, user: sshUsername, pass: sshPassword, keyPath: sshKeyPath, command: sshCommand)
                case .https:
                    fetchedTheme = try await BackendService.shared.connectHTTPS(url: backendURL, apiKey: apiKey)
                case .websocket:
                    fetchedTheme = try await BackendService.shared.connectWebSocket(url: backendURL, apiKey: apiKey)
                case .hosted:
                    fetchedTheme = try await BackendService.shared.connectHosted(apiKey: apiKey)
                case .gemini:
                    fetchedTheme = try await BackendService.shared.connectCloudLLM(provider: .gemini, apiKey: apiKey)
                case .openAI:
                    fetchedTheme = try await BackendService.shared.connectCloudLLM(provider: .openAI, apiKey: apiKey)
                case .claude:
                    fetchedTheme = try await BackendService.shared.connectCloudLLM(provider: .claude, apiKey: apiKey)
                }
                
                DispatchQueue.main.async {
                    appState.currentTheme = fetchedTheme
                    self.isConnecting = false
                    completion()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isConnecting = false
                }
            }
        }
    }
}

struct ConnectionView: View {
    @StateObject private var viewModel = ConnectionViewModel()
    @EnvironmentObject var appState: AppState
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
                
                Form {
                    Section(header: Text("Connection Protocol")) {
                        Picker("Method", selection: $viewModel.connectionProtocol) {
                            Text("Gemini").tag(ConnectionProtocol.gemini)
                            Text("OpenAI").tag(ConnectionProtocol.openAI)
                            Text("Claude").tag(ConnectionProtocol.claude)
                            Text("SSH").tag(ConnectionProtocol.ssh)
                            Text("HTTPS").tag(ConnectionProtocol.https)
                            Text("WSS").tag(ConnectionProtocol.websocket)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    
                    if viewModel.connectionProtocol == .gemini || viewModel.connectionProtocol == .openAI || viewModel.connectionProtocol == .claude {
                        Section(header: Text("\(viewModel.connectionProtocol.rawValue) Configuration")) {
                            Text("Connect directly to the cloud API.")
                                .font(.footnote).foregroundColor(.gray)
                            SecureField("API Key", text: $viewModel.apiKey)
                        }
                        .listRowBackground(Color.clear)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                    } else if viewModel.connectionProtocol == .hosted {
                        Section(header: Text("Hosted Configuration")) {
                            Text("Connect to our secure, managed cloud agent.")
                                .font(.footnote).foregroundColor(.gray)
                            SecureField("License Code", text: $viewModel.apiKey)
                        }
                        .listRowBackground(Color.clear)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                    } else if viewModel.connectionProtocol == .https || viewModel.connectionProtocol == .websocket {
                        Section(header: Text("\(viewModel.connectionProtocol == .https ? "HTTPS" : "WebSocket") Configuration")) {
                            TextField("Backend URL (e.g. \(viewModel.connectionProtocol == .https ? "http" : "ws")://192.168.1.5:8000)", text: $viewModel.backendURL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                            SecureField("API Key (Optional)", text: $viewModel.apiKey)
                        }
                        .listRowBackground(Color.clear)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
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
                        .listRowBackground(Color.clear)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        
                        Section(header: Text("Agent Command Context")) {
                            TextField("CLI Command (e.g. run_qarin.sh)", text: $viewModel.sshCommand)
                                .autocapitalization(.none)
                        }
                        .listRowBackground(Color.clear)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.connect(appState: appState) { appState.isConnected = true }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isConnecting { ProgressView().progressViewStyle(CircularProgressViewStyle()) }
                            else { Text("Connect to Agent").fontWeight(.semibold) }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isConnecting)
                    .listRowBackground(Color.clear)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Agent Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

