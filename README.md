# VisionRecall

VisionRecall is a local-first iOS companion for Meta AI glasses that turns visual context into timely reminders.

Say, “Remind me to take out the boxes when I leave home.” VisionRecall stores the reminder with local visual keys (such as the front door and boxes), then combines visual matches with time and phone context to alert you at the right moment.

## Hackathon demo

1. Register a door or object as a visual memory key.
2. Create a natural-language reminder.
3. Evaluate local signals: visual match, time, and home/departure context.
4. Deliver one local notification when confidence reaches the rule threshold.

## Planned stack

- SwiftUI and Swift 6
- Meta Wearables Device Access Toolkit for glasses camera input
- Core ML/Vision for on-device scene features
- SwiftData or SQLite for encrypted local persistence
- UserNotifications, EventKit, and Core Location for phone signals

## Privacy

Memory keys, context history, and reminder rules stay on the device. The first prototype should retain only compact matching data and use a short rolling window for raw frames. No cloud backend is required.

## Status

This is a hackathon repository. The product and implementation plan are in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/IOS_SETUP.md](docs/IOS_SETUP.md). The app has not been scaffolded yet.

## Next step

Create a SwiftUI iOS app named `VisionRecall`, add the Meta Wearables Device Access Toolkit using Swift Package Manager, and begin with the mock-device camera flow.
