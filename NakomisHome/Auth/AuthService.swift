import AuthenticationServices
import Foundation
import SwiftUI

/// Sign in with Apple → Cognito federation.
///
/// Cognito's hosted login at `<login-domain>/oauth2/authorize` brokers the
/// SiwA dance and issues Cognito JWTs at the redirect URI. We open it in
/// `ASWebAuthenticationSession`, capture the redirect with the auth code,
/// then POST to `/oauth2/token` for the access/id/refresh tokens.
@MainActor
final class AuthService: NSObject, ObservableObject {
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var userDisplayName: String?
    @Published private(set) var lastError: String?

    private var tokens: StoredTokens?

    func restore() async {
        do {
            if let stored = try TokenStore.load() {
                tokens = stored
                isSignedIn = true
                userDisplayName = Self.extractName(idToken: stored.idToken)
            }
        } catch {
            lastError = "keychain load failed: \(error)"
        }
    }

    func currentAccessToken() async -> String? {
        guard let t = tokens else { return nil }
        if t.expiresAt > Date().addingTimeInterval(60) { return t.accessToken }
        // Refresh flow: for v1 we just nudge the user back through sign-in
        // if the refresh token call hasn't been wired yet. Implemented in
        // HOME-153 follow-up.
        return t.accessToken
    }

    func signIn() async {
        let authorize = "https://\(AppConfig.cognitoLoginDomain)/oauth2/authorize"
        let params: [URLQueryItem] = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id",    value: AppConfig.cognitoClientID),
            URLQueryItem(name: "redirect_uri", value: AppConfig.cognitoRedirectURI),
            URLQueryItem(name: "scope",        value: "openid email profile"),
            URLQueryItem(name: "identity_provider", value: "SignInWithApple"),
        ]
        var comps = URLComponents(string: authorize)!
        comps.queryItems = params
        guard let url = comps.url else { return }

        do {
            let callback = try await beginAuthSession(url: url)
            guard let code = URLComponents(url: callback, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value else {
                lastError = "no auth code in callback"
                return
            }
            try await exchangeCode(code: code)
        } catch {
            lastError = "sign-in failed: \(error)"
        }
    }

    func signOut() async {
        tokens = nil
        TokenStore.clear()
        isSignedIn = false
        userDisplayName = nil
    }

    private func beginAuthSession(url: URL) async throws -> URL {
        let scheme = URL(string: AppConfig.cognitoRedirectURI)?.scheme ?? "com.nakomis.home"
        return try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { callbackURL, error in
                if let error = error { cont.resume(throwing: error); return }
                guard let callbackURL = callbackURL else { cont.resume(throwing: AuthError.noCallback); return }
                cont.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    private func exchangeCode(code: String) async throws {
        var req = URLRequest(url: URL(string: "https://\(AppConfig.cognitoLoginDomain)/oauth2/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let form: [String: String] = [
            "grant_type":   "authorization_code",
            "client_id":    AppConfig.cognitoClientID,
            "code":         code,
            "redirect_uri": AppConfig.cognitoRedirectURI,
        ]
        req.httpBody = form
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AuthError.tokenExchange(String(data: data, encoding: .utf8) ?? "")
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let id_token: String
            let refresh_token: String?
            let expires_in: Int
        }
        let body = try JSONDecoder().decode(TokenResponse.self, from: data)
        let stored = StoredTokens(
            accessToken: body.access_token,
            idToken: body.id_token,
            refreshToken: body.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(body.expires_in)),
        )
        try TokenStore.save(stored)
        tokens = stored
        userDisplayName = Self.extractName(idToken: body.id_token)
        isSignedIn = true
    }

    private static func extractName(idToken: String) -> String? {
        let parts = idToken.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var b64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while b64.count % 4 != 0 { b64 += "=" }
        guard let data = Data(base64Encoded: b64),
              let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return (claims["email"] as? String) ?? (claims["name"] as? String)
    }
}

enum AuthError: Error {
    case noCallback
    case tokenExchange(String)
}

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
