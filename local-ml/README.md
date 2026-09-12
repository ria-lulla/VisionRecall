# Local ML

This module converts sampled glasses frames into on-device, privacy-preserving visual context.

## Owns

- Vision/Core ML model loading and inference
- Scene/object labels and confidence scores
- Compact embedding generation and similarity matching
- Frame-quality checks and model-version metadata

## Interface boundary

Input is an app-owned `CapturedFrame`; output is `VisualObservation` and `VisualMatch`. Do not persist reminders, call notifications, or reference UI types here. The module may return a compact representation but does not decide retention.

## First demo

Implement a small vocabulary: `door`, `boxes`, and `exit_context`. Match a newly sampled frame against a user-registered visual key, return a normalized confidence score, and keep all processing on device.

Avoid face identification, cloud inference, and continuous high-frame-rate analysis in the hackathon build.
