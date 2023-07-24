//
//  File.swift
//  
//
//  Created by aydar.media on 24.07.2023.
//

import Foundation
import CommonCrypto

@available(macOS 10.15, *)
struct Base {
    struct NetworkError: Error {
        var message: String?
    }
    
    private static var session: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0
        return URLSession(configuration: configuration)
    }
    
    private static func getRequestFallback(url: URL) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = Base.session.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let httpResponse = response {
                    continuation.resume(returning: (data, httpResponse))
                } else {
                    continuation.resume(throwing: NSError(domain: "InvalidResponse", code: 0, userInfo: nil))
                }
            }
            task.resume()
        }
    }
    
    public static func getRequest(url: URL) async throws -> (Int, Data) {
        let (data, response): (Data, URLResponse)
        if #available(macOS 12.0, *) {
            (data, response) = try await self.session.data(from: url)
        } else {
#if DEBUG
            throw NetworkError()
#endif
#warning("no idea if it works")
            // TODO: no idea if it works
            (data, response) = try await getRequestFallback(url: url)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError() }
        
        return (httpResponse.statusCode, data)
    }
    
    public static func MD5(_ string: String) -> String {
        let data = string.data(using: .utf8)!
            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            data.withUnsafeBytes {
                _ = CC_MD5($0.baseAddress, CC_LONG(data.count), &digest)
            }
            return digest.map { String(format: "%02x", $0) }.joined()
    }
    
}
