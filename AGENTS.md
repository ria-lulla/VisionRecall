# Repository Guidelines

## Project Structure & Module Organization

VisionRecall is an iOS-first hackathon prototype for context-aware reminders using Meta AI glasses. Keep the repository organized as follows:

- `VisionRecall/` for the SwiftUI app, feature modules, and local persistence.
- `VisionRecallTests/` for unit tests and `VisionRecallUITests/` for UI tests.
- `assets/` for static, non-code resources.
- `docs/` for architecture, setup, and product decisions.

Do not commit Xcode user data, DerivedData, signing files, API keys, captured frames, or user memory data.

## Build, Test, and Development Commands

Open the future Xcode project with `open VisionRecall.xcodeproj`. Build and test from Xcode, or run:

```sh
xcodebuild -scheme VisionRecall -destination 'platform=iOS Simulator,name=iPhone 16' test
```

The Meta Wearables Device Access Toolkit is a Swift Package Manager dependency. Use its Mock Device Kit while hardware is unavailable; test final camera flows with paired glasses in Developer Mode.

## Coding Style & Naming Conventions

Use Swift 6 conventions, SwiftUI, and four-space indentation. Name types in `UpperCamelCase`, members in `lowerCamelCase`, and files after their primary type (for example, `ReminderRule.swift`). Prefer small feature-focused types and protocol-backed services for hardware and persistence boundaries.

Keep visual embeddings, captured context, and reminder state on-device. Explicitly opt out of SDK analytics and crash reporting unless the user has consented.

## Testing Guidelines

Use XCTest. Name tests as behavior statements, such as `testReminderTriggersWhenDoorAndHomeSignalsMatch()`. Test rule evaluation and local storage independently of camera hardware; use mock camera inputs for integration tests. Run the complete suite before requesting review.

## Commit & Pull Request Guidelines

Use concise, imperative subjects, such as `Add reminder rule evaluator`. Keep commits focused and avoid committing secrets.

Pull requests should describe the user-facing behavior, list tests run, link the issue when applicable, and include screenshots or a short recording for UI changes. Call out new permissions, data retention changes, and any non-local processing.
