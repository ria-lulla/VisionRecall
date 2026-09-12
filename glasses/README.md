# Glasses Integration

This module isolates Meta Wearables Device Access Toolkit integration from the rest of VisionRecall.

## Owns

- Pairing/session lifecycle and device availability
- Camera-stream start, pause, resume, and conservative frame sampling
- Photo capture when the user explicitly requests it
- Conversion of SDK frames into app-owned frame data
- Mock device/camera implementations for tests and demos

## Interface boundary

Expose protocols such as `GlassesCaptureService` and app-owned values such as `CapturedFrame`. No Meta SDK types may leave this module. This lets the rule, memory, and UI layers work with recorded fixtures or mocks.

## Privacy and scope

Request camera access only while an active feature needs it. Send sampled frames directly to `local-ml`; do not write continuous raw video to disk. Configure the Meta SDK analytics and crash-reporting opt-outs before demos.
