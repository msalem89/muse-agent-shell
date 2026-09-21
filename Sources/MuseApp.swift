import SwiftUI

class AppState: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var currentTheme: ThemeConfig = .defaultTheme
}

@main
struct MuseApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isConnected {
                MainTabView()
                    .environmentObject(appState)
            } else {
                ConnectionView()
                    .environmentObject(appState)
            }
        }
    }
}
