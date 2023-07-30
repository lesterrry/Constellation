//
//  Api.swift
//  Constellation
//
//  Created by aydar.media on 23.07.2023.
//

import Foundation

public struct User {
    public let id: String
}

@available(macOS 10.15, *)
public struct ApiClient {
    enum AuthError: Error {
        case appCodeRequestError
        case appTokenRequestError
        case userTokenRequestError
        case slnetTokenRequestError
        case unexpectedNilCredential
        case apiError(String)
        case secondFactorRequired
        case schemeFailed
        case unauthorized
    }
    
    enum ApiRequestError: Error {
        case dataNotReceived
    }
    
    private enum Prop {
        case appCode
        case appToken
        case userToken
        case slnetToken
    }
    
    private var appId: String
    private var appSecret: String
    private var userLogin: String
    private var userPassword: String
    private var appCode: String?
    private var appToken: String?
    private var userToken: String?
    private var slnetToken: String?
    
    /// Currently authorized User
    public private(set) var authorizedUser: User?
    
    public init(appId: String, appSecret: String, userLogin: String, userPassword: String) {
        self.appId = appId
        self.appSecret = appSecret
        self.userLogin = userLogin
        self.userPassword = userPassword
        
        self.userToken = getUserTokenFromKeychain()
    }
    
    /// Whether the user token is available for further auth
    public var hasUserToken: Bool {
        return self.userToken != nil
    }
    
    /// Performs a series of auth requests to Starline API, retrieving the main auth token
    /// - Parameters:
    ///   - smsCode: Optional value, should contain a valid SMS code if one was recieved as a second factor
    ///   - completion: Result callback
    public mutating func auth(smsCode: String? = nil, completion: @escaping (Result<String, Error>) -> Void) async {
        func set(_ prop: Prop) async throws {
            switch prop {
            case .appCode:
                let secret = Base.MD5(from: self.appSecret)
                let desc = try await slidRequest(to: Endpoints.Application.getCode(appId: self.appId, appSecret: secret))
                guard let code = desc.code else { throw AuthError.appCodeRequestError }
                self.appCode = code
            case .appToken:
                guard let code = self.appCode else { throw AuthError.unexpectedNilCredential }
                let secret = Base.MD5(from: self.appSecret + code)
                let desc = try await slidRequest(to: Endpoints.Application.getToken(appId: self.appId, appSecret: secret))
                guard let token = desc.token else { throw AuthError.appTokenRequestError }
                self.appToken = token
            case .userToken:
                guard let appToken = self.appToken else { throw AuthError.unexpectedNilCredential }
                let password = Base.SHA1(from: self.userPassword)
                let headers = ["token": appToken]
                var formData = ["login": self.userLogin, "pass": password]
                if smsCode != nil { formData["smsCode"] = smsCode }
                let desc = try await slidRequest(to: Endpoints.User.login, headers: headers, formData: formData)
                guard let userToken = desc.userToken, let userId = desc.id else { throw AuthError.userTokenRequestError }
                self.userToken = userToken
                self.authorizedUser = User(id: userId)
                try saveUserTokenToKeychain()
            case .slnetToken:
                guard let userToken = self.userToken else { throw AuthError.unexpectedNilCredential }
                let headers = ["Content-Type": "application/json", "Accept": "application/json"]
                let jsonData = ["slid_token": userToken]
                let data = try await apiRequest(to: Endpoints.Json.login, headers: headers, jsonData: jsonData)
                guard let slnetToken = data.realplexorId, let userId = data.userId else { throw AuthError.slnetTokenRequestError }
                self.authorizedUser = User(id: userId)
                self.slnetToken = slnetToken
            }
        }
        func walkthrough() async throws {
            if self.appCode == nil { try await set(.appCode) }
#if DEBUG
            print("Phase 1 pass: '\(self.appCode!)'")
#endif
            if self.appToken == nil { try await set(.appToken) }
#if DEBUG
            print("Phase 2 pass: '\(self.appToken!)'")
#endif
            if self.userToken == nil { try await set(.userToken) }
#if DEBUG
            print("Phase 3 pass: '\(self.userToken!)'")
#endif
            if self.slnetToken == nil { try await set(.slnetToken) }
#if DEBUG
            print("Phase 4 pass: '\(self.slnetToken!)'")
#endif
        }
        @discardableResult func validate(_ prop: Prop) -> Bool {
            switch prop {
            case .appCode: return self.appCode != nil
            case .appToken: return self.appToken != nil
            case .userToken: return self.userToken != nil
            case .slnetToken:
                if let token = self.slnetToken { completion(.success(token)); return true } else { return false }
            }
        }
        
        do {
            if validate(.slnetToken) { return }
            self.userToken = getUserTokenFromKeychain()
            if !validate(.userToken) { try await walkthrough() }
            else { try await set(.slnetToken) }
        } catch {
            completion(.failure(error)); return
        }
        
        if !validate(.slnetToken) { completion(.failure(AuthError.schemeFailed)) }
    }
    
    /// Sets the main auth token value to nil. Use if it's expired
    public mutating func invalidateSlnetToken() {
        self.slnetToken = nil
    }
    
    /// Sets the user token value to nil, also tries to remove it from the keychain. Use if it's expired
    public mutating func invalidateUserToken() {
        self.userToken = nil
        try? deleteUserTokenFromKeychain()
    }
    
    /// Retrieves the list of currently available devices for authorized user
    public func getDevicesForCurrentUser() async throws -> [ApiResponse.Device] {
        guard let token = self.slnetToken, let user = self.authorizedUser else { throw AuthError.unauthorized }
        let url = Endpoints.Json.userInfo(userId: user.id)
        let data = try await apiRequest(to: url, slnetToken: token)
        guard let devices = data.devices else { throw ApiRequestError.dataNotReceived }
        return devices
    }
    
    /// Retrieves the data for a specific device
    public func getDeviceData(for deviceId: Int) async throws -> ApiResponse.Data {
        guard let token = self.slnetToken else { throw AuthError.unauthorized }
        let url = Endpoints.Json.deviceData(deviceId: String(deviceId))
        let data = try await apiRequest(to: url, slnetToken: token)
        guard let device = data.data else { throw ApiRequestError.dataNotReceived }
        return device
    }
    
    private func getUserTokenFromKeychain() -> String? {
        // TODO: Instead of ommitting all possible exceptions I should check whether it's about the nonexistent val or smth else
        return try? Keychain.getToken(account: KeychainEntity.Account.userToken.rawValue)
    }
    
    private func saveUserTokenToKeychain() throws {
        try Keychain.saveToken(self.userToken!, account: KeychainEntity.Account.userToken.rawValue)
    }
    
    private func deleteUserTokenFromKeychain() throws {
        try Keychain.deleteToken(account: KeychainEntity.Account.userToken.rawValue)
    }
    
    private func slidRequest(to url: URL, headers: [String: String]? = nil, formData: [String: String]? = nil, jsonData: [String: String]? = nil) async throws -> SlidResponse.Desc {
        let response = try await Base.request(url: url, headers: headers, formData: formData, jsonData: jsonData)
        let data = try JSONDecoder().decode(SlidResponse.self, from: response.1)
        if data.state == 0 { throw AuthError.apiError(data.desc.message ?? "Unknown error") }
        else if data.state == 2 { throw AuthError.secondFactorRequired }
        return data.desc
    }
    
    private func apiRequest(to url: URL, headers: [String: String]? = nil, formData: [String: String]? = nil, jsonData: [String: String]? = nil, slnetToken: String? = nil) async throws -> ApiResponse {
        var requestHeaders = headers
        if let token = slnetToken {
            let cookie = "slnet=\(token)"
            if requestHeaders != nil {
                requestHeaders!["Cookie"] = cookie
            } else {
                requestHeaders = ["Cookie": cookie]
            }
        }
        let response = try await Base.request(url: url, headers: headers, formData: formData, jsonData: jsonData)
        print(String(data: response.1, encoding: .utf8))
        let data = try JSONDecoder().decode(ApiResponse.self, from: response.1)
        if data.codestring != "OK" { throw AuthError.apiError(data.codestring) }
        return data
    }
    
}