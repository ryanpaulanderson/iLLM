# AI Coding Agent Handbook for Swift iOS Apps

Opinionated rules that keep code clean, safe, and shippable. Follow them without exception unless a requirement demands otherwise.

---

Table of Contents

- [1. Scope and Targets](#1-scope-and-targets)
- [2. Project Layout](#2-project-layout)
- [3. Language, Tools, and Dependencies](#3-language-tools-and-dependencies)
- [4. Code Style](#4-code-style)
- [5. Documentation and DocC](#5-documentation-and-docc)
- [6. Architecture](#6-architecture)
- [7. Concurrency](#7-concurrency)
- [8. Networking](#8-networking)
- [9. Persistence and Caching](#9-persistence-and-caching)
- [10. UI with SwiftUI](#10-ui-with-swiftui)
- [11. Accessibility](#11-accessibility)
- [12. Localization and Internationalization](#12-localization-and-internationalization)
- [13. Errors, Logging, and Telemetry](#13-errors-logging-and-telemetry)
- [14. Configuration, Secrets, and Build Settings](#14-configuration-secrets-and-build-settings)
- [15. Security and Privacy](#15-security-and-privacy)
- [16. Testing Strategy](#16-testing-strategy)
- [17. Performance and Reliability](#17-performance-and-reliability)
- [18. CI and Delivery](#18-ci-and-delivery)
- [19. Git Hygiene and Reviews](#19-git-hygiene-and-reviews)
- [20. Definition of Done](#20-definition-of-done)
- [21. Checklists and Templates](#21-checklists-and-templates)

---

## 1. Scope and Targets

- Default to SwiftUI and Swift Concurrency on iOS 17 or later.
- Use Swift Package Manager for all third-party code.
- Support iPadOS parity where screens make sense.
- Avoid experimental APIs unless justified and guarded behind feature flags.

---

## 2. Project Layout

```text
AppRoot/
  App/                        # App entry, scenes, environment
  Features/
    <FeatureName>/
      Views/
      ViewModels/
      Models/
      Services/
      Tests/
  Core/
    Networking/
    Persistence/
    DesignSystem/
    Utilities/
  Resources/
    Assets.xcassets
    Strings.xcstrings
    PrivacyInfo.xcprivacy
  Packages/                   # Local SPM packages if any
  Docs/
    <Module>.docc/
```

- One feature per folder with the same internal structure.
- No cyclic dependencies between features.
- Core is stable and reused across features.

---

## 3. Language, Tools, and Dependencies

- Swift 5.10 or newer.
- Xcode 16 or newer.
- Formatting with SwiftFormat. Linting with SwiftLint.
- Allowed libs: Kingfisher or Nuke for images, GRDB or Core Data for storage, Combine for legacy bridging. Keep the list short.
- Prefer Foundation over custom utilities when possible.

---

## 4. Code Style

### General

- 120 character line limit. 4-space indent.
- No force unwraps. Ever. Use guard let or throw.
- Prefer let over var.
- Prefer structs and enums over classes unless reference semantics are required. Mark classes final unless subclassing is intended.
- Access control is explicit. Use private and fileprivate to reduce surface area.

### Naming

- Types and protocols: UpperCamelCase. Variables and functions: lowerCamelCase.
- Acronyms are fully cased: URL, ID, HTML.
- Protocols use capability names when meaningful: ImageLoading, SessionStoring. Do not slap Protocol on the end unless resolving a conflict.

### Optionals

- Use early returns with guard.
- Avoid nested optional pyramids. Refactor or introduce helper methods.

### Error Handling

- Throw typed errors that conform to LocalizedError for user-friendly messages.
- Do not return booleans for error states. Throw or use Result.

### Comments

- Write the code so it reads clearly. Comment why, not what.
- Keep comments in sync with code changes.

---

## 5. Documentation and DocC

- Public types, methods, and properties have doc comments.
- Use DocC catalogs under Docs/. Provide tutorials and how-to guides for core modules.
- Include code snippets that compile.
- Example doc comment:

```swift
/// Loads the current user's profile from the backend.
/// - Returns: A fully populated `UserProfile`.
/// - Throws: `NetworkError` when the request fails, or `DecodingError` for malformed data.
/// - Note: Respects the current auth session and cache headers.
func loadProfile() async throws -> UserProfile
```

---

## 6. Architecture

- MVVM with SwiftUI.
- Business logic lives in ViewModels and Services. Views stay thin.
- Dependency Injection through initializer injection. No global singletons.
- Use small protocols for seams and testing.
- Follow SOLID principles in spirit. Keep types small and focused.

Example layout for a feature:

```text
Feature/
  Models/           # Domain models
  Services/         # Protocols + impls (network, storage)
  ViewModels/
  Views/
```

---

## 7. Concurrency

- Use Swift Concurrency (async/await) and Actors for shared mutable state.
- UI code is @MainActor. Annotate ViewModels if they touch UI state.
- Avoid Task.detached. Prefer structured tasks and withTaskGroup where parallelism is needed.
- Respect cancellation. Check Task.isCancelled inside long loops.
- Avoid busy waits or arbitrary sleeps in UI logic.
- Use AsyncSequence for streams when appropriate.

---

## 8. Networking

- Use URLSession with async/await.
- Define a small HTTPClient protocol and one production implementation.
- All endpoints are typed with request and response models using Codable.
- JSON decoding strategies set explicitly. Date decoding strategy is consistent app-wide.
- Use ETags and cache control when the server supports it.
- Centralize request building and error mapping.
- Add request logging in debug builds with redaction of secrets.

Example:

```swift
protocol HTTPClient {
    func send<T: Decodable>(_ request: HTTPRequest) async throws -> T
}
```

Error mapping example:

```swift
enum NetworkError: Error, LocalizedError {
    case transport(URLError)
    case server(status: Int, message: String?)
    case decoding(DecodingError)
    case unknown

    var errorDescription: String? {
        switch self {
        case .transport(let e): return "Network issue: \(e.localizedDescription)"
        case .server(let status, _): return "Server error \(status)"
        case .decoding: return "Invalid data from server"
        case .unknown: return "Something went wrong"
        }
    }
}
```

---

## 9. Persistence and Caching

- Choose one: Core Data or GRDB. Do not mix without cause.
- If Core Data: use NSPersistentContainer with a background context for writes.
- If GRDB: wrap database access in a repository that exposes async functions.
- Use @AppStorage or UserDefaults only for simple preferences.
- Cache rules are explicit: key strategy, eviction policy, and lifetime.

---

## 10. UI with SwiftUI

- Keep View structs small. Extract subviews for clarity.
- Preview every view with at least two states.
- Avoid heavy work in body. Do it in ViewModels.
- Use the design system for colors, fonts, and spacing.
- Respect Safe Area and dynamic type.
- Navigation is data-driven where possible.

---

## 11. Accessibility

- Provide labels, hints, and traits.
- Support Dynamic Type and content size category changes.
- Meet minimum contrast using system colors or tested custom colors.
- Support VoiceOver flows.
- Respect Reduce Motion and Reduce Transparency.

---

## 12. Localization and Internationalization

- Use String Catalogs (.xcstrings). No hardcoded strings.
- Use .stringsdict for plurals.
- Avoid string interpolation for translatable content when variable order may differ.
- Support right-to-left layout.
- Format dates and numbers with FormatStyle.

---

## 13. Errors, Logging, and Telemetry

- Separate user-facing messages from technical errors.
- Use os.Logger for structured logs.
- Add signposts for critical performance paths.
- Redact PII in logs.
- Telemetry events are typed and documented. Keep the event schema versioned.

---

## 14. Configuration, Secrets, and Build Settings

- Use xcconfig files for build settings across Debug, Beta, and Release.
- Store environment values in configuration files that are safe to commit, with secret overrides in CI or the Keychain.
- Never commit API keys or tokens.
- Use feature flags for risky or staged features.

---

## 15. Security and Privacy

- Keychain for credentials and tokens.
- App Transport Security is on. Only allow exceptions with written justification.
- Implement the Privacy Manifest (PrivacyInfo.xcprivacy). Keep it current.
- Respect App Tracking Transparency. Do not gate core features on it.
- Validate third-party SDK data collection and document it.

---

## 16. Testing Strategy

- XCTest for unit and integration tests. XCUITest for UI flows.
- Aim for 80 percent line coverage on Core and Services. Coverage is a guide, not a trophy.
- Use Given-When-Then naming and arrange-act-assert structure.
- Test ViewModels without UI by injecting fakes.
- Snapshot testing only for stable, high-value views, and only after accessibility is solid.
- Use Test Plans. Run tests on at least iPhone 14 and iPhone 15 simulators.

Example test name:

```swift
func test_loadProfile_returnsDecodedUser() async throws { /* ... */ }
```

---

## 17. Performance and Reliability

- Profile with Instruments for time, allocations, and leaks.
- Avoid retain cycles. Use weak or unowned with intent and tests.
- Prefer value types for models.
- Keep images sized appropriately. Use caching for remote images.
- Use background tasks for long-running work and respect system limits.

---

## 18. CI and Delivery

- CI runs format, lint, build, tests, and static analysis on every PR.
- Fastlane or Xcode Cloud handles signing, version bump, and TestFlight upload.
- Produce release notes from merged PR titles.
- Block merges on failing checks.
- Keep build numbers auto-incremented by CI.


## 20. Definition of Done

- Lint passes and code is formatted.
- Unit tests and UI tests updated and green.
- Docs and DocC updated.
- Accessibility reviewed.
- Strings localized or marked for localization.
- Privacy manifest updated if needed.
- Feature flag documented if used.
- No crashes or leaks in basic smoke test.

---

## 21. Checklists and Templates

### New Swift File Header

```swift
//
//  <TypeName>.swift
//  <Module>
//
—
//  Created by AI Agent.
//  Description: <one line summary>
//
```

### ViewModel Template

```swift
@MainActor
final class ExampleViewModel: ObservableObject {
    @Published private(set) var state: State = .idle

    private let service: ExampleService

    init(service: ExampleService) {
        self.service = service
    }

    enum State {
        case idle
        case loading
        case loaded(Model)
        case error(String)
    }

    func load() {
        Task {
            do {
                state = .loading
                let model = try await service.fetch()
                state = .loaded(model)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}
```

### Service Protocol Template

```swift
protocol ExampleService {
    func fetch() async throws -> Model
}
```

### HTTP Request Template

```swift
struct HTTPRequest {
    var path: String
    var method: String = "GET"
    var headers: [String: String] = [:]
    var body: Data? = nil
}
```

## Final Notes

Keep the code boring, predictable, and safe. Ship value, not clever tricks.