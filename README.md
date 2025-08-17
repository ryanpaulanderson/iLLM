# iLLM — LLMChat iOS Skeleton and Technical Overview

Purpose
- Provide a clean, security-minded iOS SwiftUI MVVM skeleton for a BYOK (Bring Your Own Key) LLM chat app.
- Priorities: secure key storage, testability via protocol seams, predictable async flows, and easy extensibility for multiple LLM providers.
- Scope: app sources live under [LLMChat](LLMChat); generate an Xcode project with [project.yml](project.yml) and the top-level [Makefile](Makefile), or add sources to your own Xcode project.

At a Glance
- Platform: iOS 17+, Swift 5.10+, SwiftUI, async/await.
- Dependencies: Foundation, URLSession, Keychain Services (no third-party packages by default).
- Security: BYOK model; API keys stored in Keychain only.
- UX: Basic chat list, input with send, “thinking” indicator, settings for API key management, and model selection.
- Extensibility: Plug-in providers by conforming to a small service contract and registering them in a factory.

Architecture (High-Level)
- Pattern: MVVM with protocol-oriented services.
  - Views: declarative SwiftUI with minimal logic.
  - ViewModels: UI state, async orchestration, error mapping. Annotated for safe UI updates.
  - Services: provider-specific implementations (e.g., OpenAI-style), networking, simple caching, key handling.
- Dependency Injection: view models receive factories and storage abstractions via initializers for test seams.
- Concurrency: async/await for all network paths; UI state updated on the main actor.
- Error Handling: typed app errors surfaced to the UI; keep user-facing text separate from technical errors.
- Security: no secrets in UserDefaults or logs; HTTPS-only network calls.

Project Layout (Overview)
- [LLMChat](LLMChat)
  - App/: app entry and root navigation
  - Models/: chat message model, model metadata, API configuration
  - Services/: service contract, provider factory, provider implementations, networking, secure storage
  - ViewModels/: chat, settings, and model selection state + async workflows
  - Views/: chat list/bubbles/input, settings, model selection
  - Utils/: constants, errors, lightweight in-memory caching
  - Resources/: string catalogs (.xcstrings) for localization
  - Tests/: unit tests around bootstrapping and seams

Data Flow (Sending a Message)
1) User enters text and taps Send.
2) Chat view model appends the user message and toggles a sending/“thinking” state.
3) Conversation history and the selected model are sent to the provider’s service.
4) Service builds a typed request to the provider’s endpoint and decodes a typed response.
5) Assistant reply is appended; sending state clears; errors are mapped and presented when needed.

Security Model
- BYOK: users provide their API keys at runtime.
- Key storage: keys persist in the iOS Keychain, keyed by provider identifier (e.g., “openai”).
- Guidelines: do not log secrets; avoid plaintext storage; restrict networking to HTTPS.

Networking Strategy
- URLSession under a small, typed network layer.
- Encodable requests and Decodable responses (no manual JSON handling).
- Clear separation of transport errors, decoding errors, and server-side errors.
- Consider minimal, redacted logging in debug builds only.

Model Discovery and Caching
- Providers expose a model listing operation for the model picker UX.
- Results cached in-memory with a TTL, keyed by provider + API key.
- Cache improves startup/model selection while allowing timely refresh.

Localization and Accessibility
- Localization via string catalogs (.xcstrings); avoid hard-coded strings.
- Accessibility labels and hints for toolbar items, send actions, and loading indicators.

Testing Philosophy
- Fast, deterministic unit tests using fakes for provider, factory, and keychain seams.
- Focus on view model bootstrapping (key loading, service creation, model seed) and basic error handling.
- Use SwiftUI previews to inspect common UI states.

Extending with a New Provider (Conceptual)
1) Implement a provider service that can:
   - Send a message with conversation history and selected model.
   - List available models for presentation and selection.
   - Validate an API key (lightweight).
2) Register the provider by adding a new case/selector in the provider factory.
3) Persist and load the provider’s key using Keychain with the provider’s identifier as the account.
4) Ensure model list includes a reasonable default and identifiers/names suitable for UX display.
5) Optionally add richer error mapping and request/response types for your provider.

Build, Run, and Test

Option A — Use Your Own Xcode Project
- Create a new iOS SwiftUI app (iOS 17+).
- Add the entire [LLMChat](LLMChat) folder to your app target (ensure Target Membership is checked).
- Build and run on Simulator:
  - Open Settings in-app and paste your API key.
  - Open model selector and choose a model.
  - Start chatting.

Option B — Generate Project with XcodeGen + Make
- Requirements:
  - Xcode 16+ and command line tools.
  - XcodeGen installed (brew install xcodegen).
- Common tasks via [Makefile](Makefile):
  - Generate project from [project.yml](project.yml):
    - `make project`
  - Quick simulator test run (auto-generate if missing):
    - `make quicktest`
  - Build-for-testing and run tests without rebuilding:
    - `make test-fast`
  - Install and run the app on a booted Simulator:
    - `make install-and-run`
  - Print coverage JSON from the last test result:
    - `make coverage`

Configuration Defaults (XcodeGen)
- Bundle identifier: com.example.LLMChat
- Display name: LLMChat
- iOS target: 17.0; Swift version: 5.10
- iPhone orientation: portrait
- Unit test target depends on the app target
- See [project.yml](project.yml) for spec and overrides.

Operational Guardrails
- Do
  - Keep views declarative; move logic into view models and services.
  - Use async/await; update UI state on the main actor.
  - Inject dependencies via initializers.
  - Store secrets in Keychain only.
- Don’t
  - Force-unwrap optionals.
  - Log secrets or persist them outside Keychain.
  - Add heavy logic to view bodies.

Roadmap (Suggested)
- Streaming responses and partial tokens.
- Multiple conversations and persistence.
- Model parameter controls (temperature, max tokens, system prompts).
- Export/import transcripts.
- Provider-specific validation and error mapping.
- E2E/integration tests and UI tests with test plans.

License
- See LICENSE in the repository root.