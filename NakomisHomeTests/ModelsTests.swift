import XCTest
@testable import NakomisHome

final class ModelsTests: XCTestCase {
    func testCertRowDecodesMinimalPayload() throws {
        let json = """
        {
          "serial": "ABC",
          "cn": "martin@laptop",
          "status": "active",
          "kind": "mtls-client",
          "requested_by": "sub-1",
          "requested_at": "2026-05-14T10:00:00Z"
        }
        """.data(using: .utf8)!
        let row = try JSONDecoder().decode(CertRow.self, from: json)
        XCTAssertEqual(row.serial, "ABC")
        XCTAssertEqual(row.status, .active)
        XCTAssertEqual(row.kind, .mtlsClient)
        XCTAssertEqual(row.id, "ABC")
    }

    func testCertKindRawValuesAlignWithBackend() {
        XCTAssertEqual(CertKind.mtlsClient.rawValue, "mtls-client")
        XCTAssertEqual(CertKind.rolesAnywhere.rawValue, "roles-anywhere")
    }

    func testPendingApprovalDecodesWithToken() throws {
        let json = """
        {
          "serial": "XYZ",
          "cn": "host.test",
          "kind": "mtls-client",
          "requested_by": "sub-2",
          "requested_at": "2026-05-14T10:01:00Z",
          "approval_token": "eyJ..."
        }
        """.data(using: .utf8)!
        let p = try JSONDecoder().decode(PendingApproval.self, from: json)
        XCTAssertEqual(p.serial, "XYZ")
        XCTAssertEqual(p.approval_token, "eyJ...")
    }
}
