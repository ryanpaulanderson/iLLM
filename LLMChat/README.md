# LLMChat iOS Skeleton

SwiftUI MVVM skeleton for a BYOK LLM chat app. This repo contains app code only; create an Xcode project and include these sources.

## Requirements
- Xcode 15+
- iOS 16+ deployment target
- Swift Concurrency enabled

## Get Started in Xcode
1. Open Xcode and create a new iOS App project
   - Interface: SwiftUI
   - Language: Swift
   - Organization Identifier: your domain
   - Minimum iOS: 16.0+

2. Add the sources
   - In Xcode, right-click your app target group and choose
     Add Files to <YourApp>…
   - Select the entire local folder: LLMChat
   - Check Create folder references if you want folder colors to mirror disk or use groups as preferred
   - Ensure Target Membership is checked for all files

3. Verify project settings
   - iOS Deployment Target: 16.0 or higher
   - Disable Strict Concurrency if you plan to lower iOS targets later
   - Signing: use your personal team for device testing

4. Run
   - Build and run on Simulator
   - Open Settings button in the top-right, paste your OpenAI API key
   - Open model selector in top-left and pick a model
   - Start chatting

## Source Overview

- Application
  - [LLMChatApp](LLMChat/App/LLMChatApp.swift:1)
  - [ContentView](LLMChat/App/ContentView.swift:1)

- Models
  - [Message](LLMChat/Models/Message.swift:1)
  - [LLMModel](LLMChat/Models/LLMModel.swift:1)
  - [APIConfiguration](LLMChat/Models/APIConfiguration.swift:1)

- Services
  - Protocols
    - [LLMServiceProtocol](LLMChat/Services/Protocols/LLMServiceProtocol.swift:1)
  - Network
    - [NetworkManager](LLMChat/Services/Network/NetworkManager.swift:1)
  - Storage
    - [KeychainService](LLMChat/Services/Storage/KeychainService.swift:1)
  - LLM Providers
    - [LLMServiceFactory](LLMChat/Services/LLMService/LLMServiceFactory.swift:1)
    - [OpenAIService](LLMChat/Services/LLMService/OpenAIService.swift:1)

- ViewModels
  - [ChatViewModel](LLMChat/ViewModels/ChatViewModel.swift:1)
  - [SettingsViewModel](LLMChat/ViewModels/SettingsViewModel.swift:1)
  - [ModelSelectionViewModel](LLMChat/ViewModels/ModelSelectionViewModel.swift:1)

- Views
  - Chat
    - [ChatView](LLMChat/Views/Chat/ChatView.swift:1)
    - [MessageBubbleView](LLMChat/Views/Chat/MessageBubbleView.swift:1)
    - [MessageInputView](LLMChat/Views/Chat/MessageInputView.swift:1)
  - Settings
    - [SettingsView](LLMChat/Views/Settings/SettingsView.swift:1)
    - [APIKeyInputView](LLMChat/Views/Settings/APIKeyInputView.swift:1)
  - Model Selection
    - [ModelSelectionView](LLMChat/Views/ModelSelection/ModelSelectionView.swift:1)

- Utilities
  - [Constants](LLMChat/Utils/Constants.swift:1)
  - [AppError](LLMChat/Utils/Errors.swift:1)

## Notes

- Keychain
  - Keys are stored under service LLMChat.APIKey
  - Account name is provider identifier: openai by default
  - See [KeychainService](LLMChat/Services/Storage/KeychainService.swift:1)

- Networking
  - Standard URLSession with small typed wrapper
  - See [NetworkManager](LLMChat/Services/Network/NetworkManager.swift:1)

- Provider Architecture
  - Contract: [LLMServiceProtocol](LLMChat/Services/Protocols/LLMServiceProtocol.swift:1)
  - Factory: [LLMServiceFactory](LLMChat/Services/LLMService/LLMServiceFactory.swift:1)
  - Example impl: [OpenAIService](LLMChat/Services/LLMService/OpenAIService.swift:1)

## Add a New Provider

1. Create a new provider service conforming to [LLMServiceProtocol](LLMChat/Services/Protocols/LLMServiceProtocol.swift:1)
   - Example skeleton:

     [Swift.protocol LLMServiceProtocol](LLMChat/Services/Protocols/LLMServiceProtocol.swift:1)

2. Extend Provider enum and factory
   - Add case to Provider
   - Update switch in [LLMServiceFactory](LLMChat/Services/LLMService/LLMServiceFactory.swift:1)

3. Persist API key
   - Use [KeychainService](LLMChat/Services/Storage/KeychainService.swift:1) with account set to your provider id

4. Model selection
   - Make your service return models in availableModels()
   - The UI uses [ModelSelectionViewModel](LLMChat/ViewModels/ModelSelectionViewModel.swift:1)

## MVP UX Flow

- App boots into [ContentView](LLMChat/App/ContentView.swift:1)
- If no API key, user opens [SettingsView](LLMChat/Views/Settings/SettingsView.swift:1) and saves key
- User opens [ModelSelectionView](LLMChat/Views/ModelSelection/ModelSelectionView.swift:1) and selects a model
- Chat happens in [ChatView](LLMChat/Views/Chat/ChatView.swift:1)

## Security

- API keys never stored in UserDefaults
- All sensitive values are stored in Keychain only
- No sensitive logs