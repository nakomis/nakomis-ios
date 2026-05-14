import XCTest
@testable import NakomisHome

final class APIClientTests: XCTestCase {
    func testApproveResponseRoundTrip() throws {
        let json = """
        {
          "serial": "AAA",
          "cn": "host.test",
          "fingerprint_sha256": "01:02:03",
          "expires_at": "2027-05-14T00:00:00Z",
          "pickup_url": "https://example/pkup"
        }
        """.data(using: .utf8)!
        let r = try JSONDecoder().decode(ApproveResponse.self, from: json)
        XCTAssertEqual(r.serial, "AAA")
        XCTAssertEqual(r.pickup_url, "https://example/pkup")
    }

    func testAPIErrorDescriptionFormat() {
        let e = APIError.bad(code: 401, body: "no token")
        XCTAssertEqual(e.description, "401: no token")
    }
}
