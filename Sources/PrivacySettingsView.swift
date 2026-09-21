import SwiftUI

@MainActor
class PrivacySettingsViewModel: ObservableObject {
    @Published var shareLocation: Bool = false {
        didSet { saveSettings() }
    }
    @Published var shareContacts: Bool = false {
        didSet { saveSettings() }
    }
    @Published var isSaving: Bool = false
    
    func saveSettings() {
        isSaving = true
        Task {
            await BackendService.shared.updatePrivacySettings(shareLocation: shareLocation, shareContacts: shareContacts)
            isSaving = false
        }
    }
}

struct PrivacySettingsView: View {
    @StateObject private var viewModel = PrivacySettingsViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Device Data Sharing"), footer: Text("Your privacy is our priority. Toggle which device sensors and data your personal agent can access. All data is end-to-end encrypted.")) {
                    Toggle(isOn: $viewModel.shareLocation) {
                        Label("Location", systemImage: "location.fill")
                    }
                    
                    Toggle(isOn: $viewModel.shareContacts) {
                        Label("Contacts", systemImage: "person.crop.circle.fill")
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        appState.isConnected = false
                    }) {
                        HStack {
                            Spacer()
                            Text("Disconnect Agent")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Privacy")
        }
    }
}
