import Foundation

enum AppConfig {
    static var apiBaseURL: URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "NHApiBaseURL") as? String,
              let url = URL(string: raw) else {
            fatalError("NHApiBaseURL missing or invalid in Info.plist")
        }
        return url
    }

    static var cognitoAuthority: String {
        (Bundle.main.object(forInfoDictionaryKey: "NHCognitoAuthority") as? String) ?? ""
    }

    static var cognitoClientID: String {
        (Bundle.main.object(forInfoDictionaryKey: "NHCognitoClientID") as? String) ?? ""
    }

    static var cognitoRedirectURI: String {
        (Bundle.main.object(forInfoDictionaryKey: "NHCognitoRedirectURI") as? String) ?? ""
    }

    static var cognitoLoginDomain: String {
        (Bundle.main.object(forInfoDictionaryKey: "NHCognitoLoginDomain") as? String) ?? ""
    }
}
