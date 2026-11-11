# Nakomis Home — iOS / iPadOS app

Native SwiftUI companion app for the Nakomis home infrastructure. First feature: **manual approval of pending client-certificate issuance requests** via APNs push (with Face ID gating). Built with room to grow into a general home-control app.

## Support

If you find this useful, please consider buying me a coffee:

[![Donate with PayPal](https://www.paypalobjects.com/en_GB/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate?hosted_button_id=Q3BESC73EWVNN&custom=nakomis-ios)

## Architecture Diagram

![Architecture](docs/architecture/nakomis-ios.svg)

## Repository Layout

| Directory | Purpose |
|-----------|---------|
| `NakomisHome/`        | App source — SwiftUI views, view models, services |
| `NakomisHome/App/`    | `@main` entry point + root `TabView` |
| `NakomisHome/Auth/`   | Sign in with Apple → Cognito federation, Keychain token store |
| `NakomisHome/Push/`   | APNs registration + interactive notification handling |
| `NakomisHome/Features/Approvals/` | Cert-approval list + detail + Face ID gate |
| `NakomisHome/API/`    | Typed `APIClient` for the home-servers API |
| `NakomisHomeTests/`   | XCTest unit tests |
| `fastlane/`           | TestFlight build + upload lane |
| `project.yml`         | [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec — `*.xcodeproj` is generated on demand, not committed |

## Getting started

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. Generate the Xcode project: `xcodegen generate`
3. Open `NakomisHome.xcodeproj` in Xcode
4. Build & run on a simulator or device

Push notifications, Sign in with Apple, and the API base URL are configured via the build-time `xcconfig` and the bundle's `Info.plist`.

## Backend dependencies

The app talks to the `api.home.nakomis.com` / `api.home.sandbox.nakomis.com` HTTP API defined in [home-servers](https://github.com/nakomis/home-servers) (HOME-153). It authenticates with the shared Cognito user pool (Sign in with Apple federated in) and registers its APNs device token with the backend's `/devices` endpoint.

### Sign-in and push flows

```mermaid
sequenceDiagram
    autonumber
    participant App as iOS app<br/>(com.nakomis.home[.sandbox])
    participant Web as ASWebAuth<br/>Session
    participant Cognito as Cognito hosted UI<br/>(login.[sandbox.]nakomis.com)
    participant Apple as Apple ID<br/>(appleid.apple.com)
    participant API as HTTP API<br/>(api.home.[sandbox.]nakomis.com)
    participant Lambda as notify-approvers<br/>Lambda
    participant APNs as APNs<br/>(api.[sandbox.]push.apple.com)

    rect rgb(232, 245, 233)
        Note over App,Apple: Sign in with Apple → Cognito federation
        App->>Web: open hosted login URL
        Web->>Cognito: /oauth2/authorize
        Cognito->>Apple: redirect as OAuth client<br/>= Services ID<br/>(com.nakomis.home[.sandbox].siwa)
        Apple-->>Cognito: code → /oauth2/idpresponse
        Cognito->>Apple: token exchange signed with<br/>SiwA .p8 (key 25Z7VVWUQW)
        Apple-->>Cognito: id_token (sub, email)
        Cognito-->>App: Cognito JWT (via callback URL)
    end

    rect rgb(232, 240, 253)
        Note over App,API: Device registration
        App->>App: UIApplication.registerForRemoteNotifications
        App->>API: POST /devices { token, bundle, env }<br/>Authorization: Bearer <Cognito JWT>
        API-->>App: 204
    end

    rect rgb(253, 240, 232)
        Note over Lambda,App: Approval push (when a cert request is pending)
        Lambda->>Lambda: sign ES256 JWT with<br/>APNs .p8 (key VH26CFZ5GD)<br/>+ team 62YFUFBSFX
        Lambda->>APNs: POST /3/device/<token><br/>apns-topic: bundle id
        APNs-->>App: notification with APPROVE / DENY actions
        App->>App: Face ID gate (LAContext)
        App->>API: POST /certs/{serial}/approve<br/>Authorization: Bearer <Cognito JWT>
    end
```

The two `.p8` keys live in `~/.config/nakomis/apns/` locally and in SSM (`/home-certs/{sandbox,prod}/{apns,siwa}/private-key`). See [docs/runbooks/apple-bootstrap-home-cert-portal.md](https://github.com/nakomis/home-servers/blob/main/docs/runbooks/apple-bootstrap-home-cert-portal.md) in home-servers for the bootstrap steps.

## Architecture Diagrams

`docs/architecture/nakomis-ios.drawio` is the source for the diagram above. The SVG is auto-regenerated on commit by `.githooks/pre-commit`.

To activate the hook after cloning:

```bash
git config core.hooksPath .githooks
```

## Support

If you find this useful, please consider buying me a coffee:

[![Donate with PayPal](https://www.paypalobjects.com/en_GB/i/btn/btn_donate_SM.gif)](https://www.paypal.com/donate?hosted_button_id=Q3BESC73EWVNN&custom=nakomis-ios)
