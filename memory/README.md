# Local Memory Store

This module provides durable, on-device storage for reminders and the minimum visual context needed to evaluate them.

## Owns

- Reminder text, scheduling preferences, status, and alert history
- Registered visual keys and compact visual representations
- A bounded context timeline and retention/deletion behavior
- Repository interfaces, migrations, and test fixtures

## Data model direction

Use `Reminder`, `VisualMemoryKey`, `ContextEvent`, and `AlertDelivery` as app-owned models. Store data with SwiftData or SQLite in the app sandbox; protect it with iOS data protection. Raw captures should be optional, short-lived, and never required for the core demo.

## Recent captures

`CaptureStore` persists user-initiated photo data in the app cache's `Captures/` directory. It maintains a JSON index and prunes captures by both maximum count and maximum age (30 captures or 24 hours by default). The cache directory and individual files are excluded from device backups. The app can call `clear()` to remove all retained captures immediately.

## Boundaries

Memory accepts observations from `local-ml` and returns domain models to `rules` and the iOS app. It must not import Meta SDK, Vision/Core ML, SwiftUI, or notification frameworks.
