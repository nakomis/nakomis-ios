import LocalAuthentication
import SwiftUI

struct ApprovalDetailView: View {
    let item: PendingApproval
    @ObservedObject var vm: ApprovalsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var working = false

    var body: some View {
        Form {
            Section("Subject") {
                LabeledContent("CN", value: item.cn)
                LabeledContent("Kind", value: item.kind.rawValue)
            }
            Section("Requested by") {
                LabeledContent("User", value: item.requested_by_email ?? item.requested_by)
                LabeledContent("At", value: item.requested_at)
            }
            Section {
                Button {
                    Task { await approveWithFaceID() }
                } label: {
                    Label("Approve (Face ID)", systemImage: "checkmark.shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(working)

                Button(role: .destructive) {
                    Task { working = true; await vm.deny(item); working = false; dismiss() }
                } label: {
                    Label("Deny", systemImage: "xmark.octagon")
                        .frame(maxWidth: .infinity)
                }
                .disabled(working)
            }
        }
        .navigationTitle(item.cn)
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func approveWithFaceID() async {
        working = true
        defer { working = false }
        let ctx = LAContext()
        var nsErr: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &nsErr) else { return }
        do {
            let ok = try await ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Approve \(item.cn)")
            if ok {
                await vm.approve(item)
                dismiss()
            }
        } catch {
            // surfaced by vm
        }
    }
}
