import Foundation

enum TaskStatus: String, CaseIterable {
    case running = "Running"
    case completed = "Completed"
}

// MARK: - Dynamic AI Theme Configuration
struct ThemeConfig: Codable {
    var brandName: String
    var primaryHex: String
    var secondaryHex: String
    var useGlassmorphism: Bool
    var isTerminalStyle: Bool
    
    static let defaultTheme = ThemeConfig(
        brandName: "Personal AI",
        primaryHex: "#007AFF", // Standard iOS Blue
        secondaryHex: "#5856D6",
        useGlassmorphism: true,
        isTerminalStyle: false
    )
}

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AgentTask: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    var status: TaskStatus
}

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let isUser: Bool
    let text: String?
    let associatedTask: AgentTask?
}
