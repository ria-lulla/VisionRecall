# VisionRecall Architecture

## Goal

Turn a spoken reminder into a local rule that can react to visual, time, and phone signals.

## Data flow

```text
Glasses camera → sampled frame → local feature extraction → memory-key match
Voice/text intent → reminder + trigger rule ───────────────────────────────┐
Phone signals (time, location, calendar) ─────────────────────────────────┼→ rule evaluator → local alert
Local memory store ────────────────────────────────────────────────────────┘
```

## Core components

- **Capture service:** receives Meta Wearables camera frames and samples them at a conservative rate.
- **Vision service:** produces local object/scene labels and compact embeddings; it need not retain every image.
- **Memory store:** persists reminders, keys, confidence thresholds, and a bounded context timeline locally.
- **Rule evaluator:** combines signals into a confidence score and suppresses duplicate alerts.
- **Notification service:** sends a local notification and records delivery or dismissal.

## First demo rule

`boxes reminder` triggers once when the user is at home, a door/exit context matches, and the time is in an allowed window. Treat a visual match as one input, not sufficient evidence by itself.

## Boundaries

Keep Meta SDK access behind a protocol so a mock implementation can drive tests and demos. Do not build cloud sync, continuous raw-video storage, person recognition, or autonomous actions for the hackathon.
