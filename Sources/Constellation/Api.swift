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
        case unexpectedNilCredential
        case apiError(String)
        case secondFactorRequired
    }
    
    private enum Prop {
        case appCode
        case appToken
        case userToken
    }
    
    public private(set) var appID: String
    public private(set) var appSecret: String
    public private(set) var userLogin: String
    public private(set) var userPassword: String
    public private(set) var appCode: String?
    public private(set) var appToken: String?
    public private(set) var userToken: String?
    
    public init(appID: String, appSecret: String, userLogin: String, userPassword: String) {
        self.appID = appID
        self.appSecret = appSecret
        self.userLogin = userLogin
        self.userPassword = userPassword
    }
    
    public mutating func auth(completion: @escaping (Result<Data, Error>) -> Void) async {
        func set(_ prop: Prop) async throws {
            switch prop {
            case .appCode:
                let secret = Base.MD5(from: self.appSecret)
                let desc = try await genericRequest(to: Endpoints.Application.getCode(appID: self.appID, appSecret: secret))
                guard let code = desc.code else { throw AuthError.appCodeRequestError }
                self.appCode = code
            case .appToken:
                guard let code = self.appCode else { throw AuthError.unexpectedNilCredential }
                let secret = Base.MD5(from: self.appSecret + code)
                let desc = try await genericRequest(to: Endpoints.Application.getToken(appID: self.appID, appSecret: secret))
                guard let token = desc.token else { throw AuthError.appTokenRequestError }
                self.appToken = token
            case .userToken:
                guard let token = self.appToken else { throw AuthError.unexpectedNilCredential }
                let password = Base.SHA1(from: self.userPassword)
                let headers = [
                    "token": token
                ]
                let formData = [
                    "login": self.userLogin,
                    "pass": password
                ]
                let _ = try await genericRequest(to: Endpoints.User.login, headers: headers, formData: formData)
            }
        }
        
        do {
            if self.appCode == nil { try await set(.appCode) }
            print("Phase 1 pass: '\(self.appCode!)'")
            if self.appToken == nil { try await set(.appToken) }
            print("Phase 2 pass: '\(self.appToken!)'")
            if self.userToken == nil { try await set(.userToken) }
            print("Phase 3 pass: '\(self.userToken)'")
        } catch {
            completion(.failure(error))
        }
        
//                completion(.success(data))

    }
    
    private func genericRequest(to url: URL, headers: [String: String]? = nil, formData: [String: String]? = nil) async throws -> GenericResponse.Desc {
        let response = try await Base.request(url: url, headers: headers, formData: formData)
        let data = try JSONDecoder().decode(GenericResponse.self, from: response.1)
        if data.state == 0 { throw AuthError.apiError(data.desc.message ?? "Unknown error") }
        else if data.state == 2 { print(data.desc.message); throw AuthError.secondFactorRequired }
        return data.desc
    }

}
