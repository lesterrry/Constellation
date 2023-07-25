//
//  Api.swift
//  Constellation
//
//  Created by aydar.media on 23.07.2023.
//

import Foundation

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
    }
    
    private enum Prop {
        case appCode
        case appToken
        case userToken
        case slnetToken
    }
    
    public private(set) var appID: String
    public private(set) var appSecret: String
    public private(set) var userLogin: String
    public private(set) var userPassword: String
    public private(set) var appCode: String?
    public private(set) var appToken: String?
    public private(set) var userToken: String?
    public private(set) var slnetToken: String?
    
    public init(appID: String, appSecret: String, userLogin: String, userPassword: String) {
        self.appID = appID
        self.appSecret = appSecret
        self.userLogin = userLogin
        self.userPassword = userPassword
    }
    
    public mutating func auth(smsCode: String? = nil, completion: @escaping (Result<String, Error>) -> Void) async {
        func set(_ prop: Prop) async throws {
            switch prop {
            case .appCode:
                let secret = Base.MD5(from: self.appSecret)
                let desc = try await slidRequest(to: Endpoints.Application.getCode(appID: self.appID, appSecret: secret))
                guard let code = desc.code else { throw AuthError.appCodeRequestError }
                self.appCode = code
            case .appToken:
                guard let code = self.appCode else { throw AuthError.unexpectedNilCredential }
                let secret = Base.MD5(from: self.appSecret + code)
                let desc = try await slidRequest(to: Endpoints.Application.getToken(appID: self.appID, appSecret: secret))
                guard let token = desc.token else { throw AuthError.appTokenRequestError }
                self.appToken = token
            case .userToken:
                guard let appToken = self.appToken else { throw AuthError.unexpectedNilCredential }
                let password = Base.SHA1(from: self.userPassword)
                let headers = ["token": appToken]
                var formData = ["login": self.userLogin, "pass": password]
                if smsCode != nil { formData["smsCode"] = smsCode; print("Running with SMS Code") }
                let desc = try await slidRequest(to: Endpoints.User.login, headers: headers, formData: formData)
                guard let userToken = desc.user_token else { throw AuthError.userTokenRequestError }
                self.userToken = userToken
            case .slnetToken:
                guard let userToken = self.userToken else { throw AuthError.unexpectedNilCredential }
                let headers = ["Content-Type": "application/json", "Accept": "application/json"]
                let jsonData = ["slid_token": userToken]
                let data = try await apiRequest(to: Endpoints.Json.login, headers: headers, jsonData: jsonData)
                guard let slnetToken = data.realplexor_id else { throw AuthError.slnetTokenRequestError }
                self.slnetToken = slnetToken
            }
        }
        
        do {
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
            print("Phase 4 pass: '\(self.slnetToken)'")
#endif
        } catch {
            completion(.failure(error)); return
        }
        
        if let slnetToken = self.slnetToken { completion(.success(slnetToken)) }
        else { completion(.failure(AuthError.schemeFailed)) }
    }
    
    private func slidRequest(to url: URL, headers: [String: String]? = nil, formData: [String: String]? = nil, jsonData: [String: String]? = nil) async throws -> SlidResponse.Desc {
        let response = try await Base.request(url: url, headers: headers, formData: formData, jsonData: jsonData)
        let data = try JSONDecoder().decode(SlidResponse.self, from: response.1)
        if data.state == 0 { throw AuthError.apiError(data.desc.message ?? "Unknown error") }
        else if data.state == 2 { print(data.desc.message); throw AuthError.secondFactorRequired }
        return data.desc
    }
    
    private func apiRequest(to url: URL, headers: [String: String]? = nil, formData: [String: String]? = nil, jsonData: [String: String]? = nil) async throws -> ApiResponse {
        let response = try await Base.request(url: url, headers: headers, formData: formData, jsonData: jsonData)
        let data = try JSONDecoder().decode(ApiResponse.self, from: response.1)
        if data.code != 200 { throw AuthError.apiError("\(data.code): \(data.codestring)") }
        return data
    }

}
