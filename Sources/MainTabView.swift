import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                }
            
            TaskDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
            
            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "lock.shield.fill")
                }
        }
    }
}
