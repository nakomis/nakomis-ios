import Foundation
import LocalAuthentication
import UserNotifications

/// Handles APNs interactive notifications. Approve/Deny actions arrive here
/// even when the app is in the background or the device is locked.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    // Show banner while in foreground too.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        guard
            response.notification.request.content.categoryIdentifier == "APPROVE_CERT",
            let token = userInfo["approval_token"] as? String,
            let serial = userInfo["serial"] as? String
        else {
            completionHandler()
            return
        }

        let action = response.actionIdentifier

        Task {
            await handle(action: action, approvalToken: token, serial: serial)
            completionHandler()
        }
    }

    @MainActor
    private func handle(action: String, approvalToken: String, serial: String) async {
        do {
            let access = await AuthBootstrap.shared.currentAccessToken()
            guard let access else {
                print("no access token available to act on notification \(serial)")
                return
            }
            let client = APIClient(authToken: access)

            switch action {
            case "APPROVE", UNNotificationDefaultActionIdentifier:
                let ok = try await authenticateWithBiometrics(reason: "Approve client certificate \(serial)")
                guard ok else { return }
                _ = try await client.approve(token: approvalToken)
            case "DENY":
                _ = try await client.deny(token: approvalToken)
            default:
                break
            }
        } catch {
            print("notification handling failed: \(error)")
        }
    }

    private func authenticateWithBiometrics(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use passcode"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    }
}

/// Minimal singleton bridge so the notification handler (a UNUserNotificationCenterDelegate
/// owned by AppDelegate) can reach the access token without an env-object.
@MainActor
final class AuthBootstrap {
    static let shared = AuthBootstrap()
    weak var auth: AuthService?
    func currentAccessToken() async -> String? { await auth?.currentAccessToken() }
}
