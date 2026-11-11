import SwiftUI

struct ApprovalsView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var vm: ApprovalsViewModel

    init() {
        // Placeholder auth; the shared environment instance is bound in .task
        // before the first refresh (EnvironmentObject isn't available in init).
        _vm = StateObject(wrappedValue: ApprovalsViewModel(auth: AuthService()))
    }

    var body: some View {
        NavigationStack {
            List {
                if vm.loading { ProgressView() }
                if let err = vm.error {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
                if vm.pending.isEmpty && !vm.loading {
                    Text("No pending approvals").foregroundStyle(.secondary)
                }
                ForEach(vm.pending) { item in
                    NavigationLink(destination: ApprovalDetailView(item: item, vm: vm)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.cn).font(.headline)
                            HStack {
                                Text(item.kind.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                                Text(item.requested_by_email ?? item.requested_by)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pending approvals")
            .refreshable { await vm.refresh() }
            .task { vm.attach(auth); await vm.refresh() }
        }
    }
}
