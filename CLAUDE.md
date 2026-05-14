# Nakomis Home — iOS / iPadOS

Native SwiftUI app. First feature is cert-approval; the app is built as a general home-control shell with `TabView` so future features land as new tabs without restructuring.

## Apple Developer Portal

- Apple Developer Program is active (£79/yr).
- App ID: `com.nakomis.home` (prod), `com.nakomis.home.sandbox` (sandbox).
- Capabilities: **Push Notifications**, **Sign in with Apple**.
- APNs auth key (`.p8`) is uploaded **once** into AWS SSM SecureString at `/home-certs/{env}/apns/private-key` (created by `CertPortalApnsStack` in home-servers).
- Sign in with Apple Services ID + private key uploaded into SSM at `/home-certs/{env}/siwa/*` (used by Cognito federation in home-servers).

Bootstrap runbook (one-time): `home-servers/docs/runbooks/ios-bootstrap.md`.

## Repository layout

| Directory | Purpose |
|-----------|---------|
| `NakomisHome/`        | App source |
| `NakomisHome/App/`    | `@main` + root view |
| `NakomisHome/Auth/`   | Sign in with Apple → Cognito federation |
| `NakomisHome/Push/`   | APNs registration + handling |
| `NakomisHome/Features/Approvals/` | Cert approval feature |
| `NakomisHome/API/`    | Backend client |
| `NakomisHomeTests/`   | XCTest |
| `fastlane/`           | TestFlight |
| `project.yml`         | XcodeGen spec |

`*.xcodeproj` is generated on demand and **not committed** — see `project.yml`.

## Project generation

```bash
brew install xcodegen   # one-time
xcodegen generate       # regenerates NakomisHome.xcodeproj
```

## Testing

```bash
xcodebuild test \
  -project NakomisHome.xcodeproj \
  -scheme NakomisHome \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Minimum coverage target: 70%.

## Distribution

TestFlight only (internal testers). The fastlane `beta` lane builds + uploads:

```bash
cd fastlane && fastlane beta
```

## Architecture diagrams

Source: `docs/architecture/nakomis-ios.drawio` — SVG auto-regenerated on commit by `.githooks/pre-commit`.

To activate the hook after cloning:
```bash
git config core.hooksPath .githooks
```

## Branding / language

British English throughout user-facing strings — colour, licence, realise, whilst, etc.
