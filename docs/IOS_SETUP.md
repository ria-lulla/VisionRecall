# iOS and Meta Wearables Setup

## Prerequisites

- Xcode with a current iOS SDK
- An Apple development team for device notifications and permissions
- Meta AI app and compatible Meta glasses for hardware testing
- Meta Wearables Developer Center project and Developer Mode enabled on the glasses

## Create the app

Create an iOS App in Xcode named `VisionRecall` using SwiftUI. Add Meta's iOS Device Access Toolkit through Swift Package Manager:

`https://github.com/facebook/meta-wearables-dat-ios`

Begin with the toolkit's sample app or Mock Device Kit. It allows camera-stream and permission behavior to be tested without glasses.

## Required permissions

Request only permissions used by the demo: notifications, location for the home trigger, calendar only if it appears in the demo, and camera/device access through the Meta toolkit. Explain each permission in the UI before invoking the system prompt.

## Privacy configuration

The Meta toolkit's analytics and crash reporting are enabled by default. Add the documented `MWDAT` opt-out entries to `Info.plist` before presenting the app as local-first. Keep developer credentials and any device identifiers out of version control.

## Scope guardrails

The toolkit is in developer preview. Build the prototype for on-device testing and demo sharing; do not assume public App Store distribution is available yet.
