import Foundation
import SwiftUI
import UserNotifications
import UIKit

@MainActor
final class PushService: ObservableObject {
    static let shared = PushService()

    enum Status: String, CustomStringConvertible {
        case unknown      = "unknown"
        case notDetermined = "not determined"
        case denied       = "denied"
        case granted      = "granted"
        case registering  = "registering"
        case registered   = "registered"

        var description: String { rawValue }
    }

    @Published var deviceToken: String?
    @Published var status: Status = .unknown

    private var lastAuthRef: AuthService?
    private var pendingRegistration = false

    /// Called after sign-in. Idempotent.
    func registerIfNeeded(using auth: AuthService) async {
        lastAuthRef = auth
        let center = UNUserNotificationCenter.current()

        let approveAction = UNNotificationAction(
            identifier: "APPROVE",
            title: "Approve",
            options: [.authenticationRequired, .foreground],
        )
        let denyAction = UNNotificationAction(
            identifier: "DENY",
            title: "Deny",
            options: [.destructive, .authenticationRequired],
        )
        let category = UNNotificationCategory(
            identifier: "APPROVE_CERT",
            actions: [approveAction, denyAction],
            intentIdentifiers: [],
            options: [.customDismissAction],
        )
        center.setNotificationCategories([category])

        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        status = granted ? .granted : .denied
        if !granted { return }

        status = .registering
        pendingRegistration = true
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Called by AppDelegate once APNs returns a token.
    func notifyTokenAvailable() {
        guard let auth = lastAuthRef else { return }
        Task {
            await self.uploadToken(using: auth)
        }
    }

    private func uploadToken(using auth: AuthService) async {
        guard let token = deviceToken,
              let access = await auth.currentAccessToken() else { return }
        do {
            try await APIClient(authToken: access).registerDevice(token: token)
            status = .registered
            pendingRegistration = false
        } catch {
            print("device registration failed: \(error)")
        }
    }
}
