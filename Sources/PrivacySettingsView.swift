import SwiftUI

struct PrivacySettingsView: View {
    @StateObject private var deviceManager = DeviceManager.shared
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        let theme = appState.currentTheme
        
        Form {
            Section(header: Text("Device Integration Context"), footer: Text("Granting these permissions allows \(theme.brandName) to fetch live data from your iPhone to provide better contextual answers. Data is only sent to your configured backend.")) {
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Location Services")
                        Text("Allows the agent to know where you are.")
                            .font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    if deviceManager.isLocationAuthorized {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else {
                        Button("Allow") {
                            deviceManager.requestLocationAccess()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.red)
                    VStack(alignment: .leading) {
                        Text("Calendar Events")
                        Text("Allows the agent to read and schedule events.")
                            .font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    if deviceManager.isCalendarAuthorized {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else {
                        Button("Allow") {
                            deviceManager.requestCalendarAccess { _ in }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Contacts")
                        Text("Allows the agent to look up emails and numbers.")
                            .font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    if deviceManager.isContactsAuthorized {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else {
                        Button("Allow") {
                            deviceManager.requestContactsAccess { _ in }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .listRowBackground(theme.useGlassmorphism ? Color.clear : Color(UIColor.secondarySystemGroupedBackground))
            .background(theme.useGlassmorphism ? .ultraThinMaterial : .regularMaterial)
            .cornerRadius(10)
        }
        .scrollContentBackground(.hidden)
        .background(
            Group {
                if theme.isTerminalStyle {
                    Color.black.ignoresSafeArea()
                } else if theme.useGlassmorphism {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: theme.primaryHex).opacity(0.1), Color(hex: theme.secondaryHex).opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ).ignoresSafeArea()
                } else {
                    Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                }
            }
        )
        .navigationTitle("Agent Context")
        .navigationBarTitleDisplayMode(.inline)
    }
}
