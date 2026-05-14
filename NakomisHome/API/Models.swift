import Foundation

enum CertStatus: String, Codable {
    case pending, approved, denied, active, revoked, expired
}

enum CertKind: String, Codable {
    case mtlsClient = "mtls-client"
    case rolesAnywhere = "roles-anywhere"
}

struct CertRow: Codable, Identifiable {
    var serial: String
    var cn: String
    var san: [String]?
    var status: CertStatus
    var kind: CertKind
    var source: String?
    var requested_by: String
    var requested_by_email: String?
    var requested_at: String
    var approved_at: String?
    var approved_by: String?
    var issued_at: String?
    var expires_at: String?
    var revoked_at: String?
    var fingerprint_sha256: String?

    var id: String { serial }
}

struct PendingApproval: Codable, Identifiable {
    var serial: String
    var cn: String
    var kind: CertKind
    var requested_by: String
    var requested_by_email: String?
    var requested_at: String
    var approval_token: String?

    var id: String { serial }
}

struct ApproveResponse: Codable {
    var serial: String
    var cn: String
    var fingerprint_sha256: String
    var expires_at: String
    var pickup_url: String
}
