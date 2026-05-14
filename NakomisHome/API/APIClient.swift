import Foundation
import UIKit

struct APIClient {
    let authToken: String
    let baseURL: URL = AppConfig.apiBaseURL
    let session: URLSession = .shared

    func listPending() async throws -> [PendingApproval] {
        struct R: Decodable { let pending: [PendingApproval] }
        let r: R = try await get("/approvals")
        return r.pending
    }

    func approve(token: String) async throws -> ApproveResponse {
        try await post("/approvals/\(token)")
    }

    func deny(token: String) async throws -> EmptyOK {
        try await post("/approvals/\(token)/deny")
    }

    func registerDevice(token: String) async throws {
        struct Body: Encodable { let device_token: String; let platform: String; let app_version: String }
        let v = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
        _ = try await postJSON("/devices",
                               body: Body(device_token: token,
                                          platform: UIDeviceKind.current.rawValue,
                                          app_version: v)) as EmptyOK
    }

    // MARK: -

    private func get<T: Decodable>(_ path: String) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "GET"
        req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        return try await send(req)
    }

    private func post<T: Decodable>(_ path: String) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        return try await send(req)
    }

    private func postJSON<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        return try await send(req)
    }

    private func send<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.bad(code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                               body: String(data: data, encoding: .utf8) ?? "")
        }
        if T.self == EmptyOK.self { return EmptyOK() as! T }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

struct EmptyOK: Codable {}

enum APIError: Error, CustomStringConvertible {
    case bad(code: Int, body: String)
    var description: String {
        switch self {
        case .bad(let code, let body): return "\(code): \(body)"
        }
    }
}

private enum UIDeviceKind: String {
    case ios = "ios", ipados = "ipados"

    static var current: UIDeviceKind {
        if UIDevice.current.userInterfaceIdiom == .pad { return .ipados }
        return .ios
    }
}
