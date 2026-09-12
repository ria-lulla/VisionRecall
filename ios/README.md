# iOS App

This directory will contain the Xcode project and the user-facing SwiftUI application.

## Owns

- App launch, dependency composition, and navigation
- Permission education and system prompts
- Reminder creation, timeline, and settings UI
- Local notification presentation and deep links
- iOS adapters for location, calendar, and notification APIs

## Does not own

The app layer must not contain frame analysis, Meta device-session logic, database queries, or trigger scoring. It calls the `glasses`, `local-ml`, `memory`, and `rules` interfaces instead.

## Target layout

```text
ios/
  VisionRecall.xcodeproj
  VisionRecall/          app source
  VisionRecallTests/     unit tests
  VisionRecallUITests/   UI tests
```

Start with a SwiftUI app target named `VisionRecall`. Keep feature views under `VisionRecall/Features/` and composition/permission code under `VisionRecall/App/`.
