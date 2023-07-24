//
//  Api.swift
//  Constellation
//
//  Created by aydar.media on 23.07.2023.
//

import Foundation

@available(macOS 10.15, *)
public struct ApiClient {
    public private(set) var appID: String
    public private(set) var secret: String
    
    public init(appID: String, secret: String) {
        self.appID = appID
        self.secret = secret
    }
    
    public func auth(completion: @escaping (Result<Data, Error>) -> Void) async {
        let r = try? await Base.getRequest(url: Constant.Endpoints.getCode(appID: self.appID, secret: self.secret))
        print(r)
        
//        let task = URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//            } else if let data = data {
//                completion(.success(data))
//            }
//        }
//        task.resume()
    }

}
