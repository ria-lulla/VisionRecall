# VisionRecall

VisionRecall is an agent that lives on Ray-Ban Meta glasses. It solves a specific failure: you know what you need to do, but the moment where knowing meets being able to act never arrives.

It runs a closed loop in two directions:

- **Forward:** VisionRecall notices obligations in the world and silently creates tasks. Those tasks land in a lightweight inbox you can clear in thirty seconds a day, keeping junk out of your trusted list.
- **Backward:** From confirmed tasks, VisionRecall derives the real-world precondition needed to act—such as the box by the door while you are leaving, an empty container entering view, or returning to the desk where something was left half-finished—and watches for it to be satisfied.

When the moment arrives, VisionRecall does not nag. It has already completed the first step: the appointment slot is held, the form is prefilled, or the draft is written. You only need to confirm. When it sees a task has been completed, it closes the task automatically.

Say, “Remind me to take out the boxes when I leave home.” VisionRecall stores the reminder with local visual keys (such as the front door and boxes), then combines visual matches with time and phone context to prepare the action at the right moment.

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

## Repository layout

```text
ios/       iOS app shell, UI, permissions, and dependency composition
glasses/   Meta Wearables camera/session adapter and mock device support
local-ml/  on-device frame analysis, scene labels, and embeddings
memory/    local reminder, visual-key, and context persistence
rules/     deterministic multi-signal trigger evaluation
docs/      product, architecture, and setup decisions
```

Each area has a local README that defines its responsibilities and boundaries. Keep cross-module dependencies flowing toward the domain: the iOS app composes modules; glasses and local ML provide signals; memory and rules do not depend on UI or Meta SDK types.

## Privacy

Memory keys, context history, and reminder rules stay on the device. The first prototype should retain only compact matching data and use a short rolling window for raw frames. No cloud backend is required.

## Status

This is a hackathon repository. The product and implementation plan are in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/IOS_SETUP.md](docs/IOS_SETUP.md). The app has not been scaffolded yet.

## Next step

Create a SwiftUI iOS app named `VisionRecall`, add the Meta Wearables Device Access Toolkit using Swift Package Manager, and begin with the mock-device camera flow.
