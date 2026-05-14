import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        if auth.isSignedIn {
            TabView {
                ApprovalsView()
                    .tabItem { Label("Approvals", systemImage: "checkmark.shield") }

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
            .tint(Color("AccentColor"))
        } else {
            SignInView()
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var push: PushService

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Signed in as", value: auth.userDisplayName ?? "—")
                    Button("Sign out", role: .destructive) { Task { await auth.signOut() } }
                }
                Section("Push") {
                    LabeledContent("Device token", value: push.deviceToken.map { String($0.prefix(12)) + "…" } ?? "not registered")
                    LabeledContent("Status", value: push.status.description)
                }
                Section("API") {
                    LabeledContent("Base URL", value: AppConfig.apiBaseURL.absoluteString)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
