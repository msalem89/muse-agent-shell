import SwiftUI

enum ConnectionProtocol: String, CaseIterable, Identifiable {
    case https = "HTTPS / API"
    case ssh = "SSH / CLI"
    var id: Self { self }
}

@MainActor
class ConnectionViewModel: ObservableObject {
    @Published var connectionProtocol: ConnectionProtocol = .ssh
    
    // HTTPS Fields
    @Published var backendURL: String = ""
    @Published var apiKey: String = ""
    
    // SSH Fields
    @Published var sshHost: String = ""
    @Published var sshPort: String = "22"
    @Published var sshUsername: String = ""
    @Published var sshPassword: String = ""
    @Published var sshCommand: String = "python nafs/run_qarin.py"
    
    @Published var isConnecting: Bool = false
    
    func connect(completion: @escaping () -> Void) {
        isConnecting = true
        Task {
            do {
                if connectionProtocol == .ssh {
                    try await BackendService.shared.connectSSH(host: sshHost, port: sshPort, user: sshUsername, pass: sshPassword, command: sshCommand)
                } else {
                    try await BackendService.shared.connectHTTPS(url: backendURL, apiKey: apiKey)
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
                
                if viewModel.connectionProtocol == .https {
                    Section(header: Text("HTTPS Configuration")) {
                        TextField("Backend URL (e.g. http://192.168.1.5:8000)", text: $viewModel.backendURL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                        SecureField("API Key (Optional)", text: $viewModel.apiKey)
                    }
                } else {
                    Section(header: Text("SSH Configuration")) {
                        TextField("Host / IP Address", text: $viewModel.sshHost)
                            .keyboardType(.numbersAndPunctuation)
                            .autocapitalization(.none)
                        TextField("Port", text: $viewModel.sshPort)
                            .keyboardType(.numberPad)
                        TextField("Username", text: $viewModel.sshUsername)
                            .autocapitalization(.none)
                        SecureField("Password / Key Phrase", text: $viewModel.sshPassword)
                    }
                    
                    Section(header: Text("Agent Command Context")) {
                        TextField("CLI Command (e.g. run_qarin.sh)", text: $viewModel.sshCommand)
                            .autocapitalization(.none)
                    }
                }
                
                Button(action: {
                    viewModel.connect {
                        appState.isConnected = true
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isConnecting {
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Connect to Agent System")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isConnecting)
            }
            .navigationTitle("Agent Connection")
        }
    }
}

