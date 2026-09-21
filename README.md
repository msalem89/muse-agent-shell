# Personal AI iOS App (The Shell)

A native, privacy-first iOS application built with SwiftUI that acts as a remote "Shell" for your Personal AI Agent backend (e.g., Nafs). 

This app allows you to connect to your personal, self-hosted AI orchestrator from anywhere in the world using robust, secure protocols, keeping your data entirely in your control.

## Features

- **Multi-Protocol Support**: Connect to your agent via:
  - **SSH / CLI**: Execute shell commands directly on your desktop agent environment, with full support for Private Key authentication.
  - **HTTPS (REST)**: Communicate with local or remote APIs (like a FastAPI orchestrator).
  - **WebSocket (WSS)**: Real-time streaming for token-by-token LLM generation and instant task updates.
  - **Hosted (Cloud)**: A fallback option for App Store review and managed cloud deployments.
- **Dynamic Glassmorphism UI**: Beautiful, modern translucent interfaces that automatically adapt to your iPhone's system theme (Light Pastel / Dark Mode).
- **Rich Task Cards**: See exactly what background tasks your agent is running directly in the chat stream (e.g., "Booking Flight", "Researching Topic").
- **Privacy First**: All data stays between the iOS client and your configured backend node.

## Architecture

This iOS application is designed as a "thin client". The actual heavy lifting (LLM context management, tool execution, browser automation) happens on your backend node. 

### Dependencies
- **SwiftUI**: Modern declarative UI framework.
- **Citadel (NIOSSH)**: Provides native, robust SSH tunneling and command execution from the iPhone.

## Getting Started

1. Clone this repository.
2. Ensure you have `xcodegen` installed (`brew install xcodegen`).
3. Run `xcodegen generate` to build the `.xcodeproj` file.
4. Open `MuseClone.xcodeproj` in Xcode 15+ and run it on your simulator or device.
