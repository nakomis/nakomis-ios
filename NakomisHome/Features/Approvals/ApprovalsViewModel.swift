import Foundation
import SwiftUI

@MainActor
final class ApprovalsViewModel: ObservableObject {
    @Published var pending: [PendingApproval] = []
    @Published var error: String?
    @Published var loading: Bool = false

    private let auth: AuthService

    init(auth: AuthService) { self.auth = auth }

    func refresh() async {
        loading = true
        defer { loading = false }
        do {
            guard let access = await auth.currentAccessToken() else {
                error = "not authenticated"
                return
            }
            let client = APIClient(authToken: access)
            pending = try await client.listPending()
            error = nil
        } catch {
            self.error = "\(error)"
        }
    }

    func approve(_ item: PendingApproval) async {
        await act(item) { client, token in _ = try await client.approve(token: token) }
    }

    func deny(_ item: PendingApproval) async {
        await act(item) { client, token in _ = try await client.deny(token: token) }
    }

    private func act(_ item: PendingApproval, _ body: @escaping (APIClient, String) async throws -> Void) async {
        do {
            guard let access = await auth.currentAccessToken(),
                  let token = item.approval_token else {
                error = "missing token"
                return
            }
            let client = APIClient(authToken: access)
            try await body(client, token)
            await refresh()
        } catch {
            self.error = "\(error)"
        }
    }
}
