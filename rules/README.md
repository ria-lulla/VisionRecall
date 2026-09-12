# Reminder Rules

This module decides whether the current context is sufficient to send a reminder.

## Owns

- Parsing normalized trigger criteria into explicit rule data
- Combining visual confidence, time, location, calendar, and device signals
- Thresholds, cool-down windows, one-time completion, and duplicate suppression
- Pure unit tests for every trigger scenario

## Rule shape

Keep evaluation deterministic and explainable. For the first demo, a rule can require `atHome`, an allowed time window, and an `exit_context` visual match above a threshold. Return an `EvaluationResult` that includes the reason and contributing signals.

## Boundaries

Rules consume domain values from `memory` and signal adapters; they do not read the database, invoke the Meta SDK, or send notifications. The iOS app handles delivery after the evaluator recommends an alert.
