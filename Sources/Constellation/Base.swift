//
//  Base.swift
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
    
    private static func getRequestFallback(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
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
    
    public static func request(url: URL, headers: [String: String]? = nil, formData: [String: String]? = nil, jsonData: [String: String]? = nil) async throws -> (Int, Data) {
        var request = URLRequest(url: url)
            
        request.httpMethod = (formData == nil && jsonData == nil) ? "GET" : "POST"
        
        // Set headers
        if headers != nil {
            for (key, value) in headers! {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Set the form data
        if formData != nil {
            let bodyComponents = formData!.map { key, value in
                return "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            }
            request.httpBody = bodyComponents.joined(separator: "&").data(using: .utf8)
        } else if jsonData != nil {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonData!, options: [])
        }
        
        request.timeoutInterval = 15.0
        
        let (data, response): (Data, URLResponse)
        if #available(macOS 12.0, *) {
            (data, response) = try await URLSession.shared.data(for: request)
        } else {
#warning("no idea if it works")
            (data, response) = try await getRequestFallback(request)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError() }
        
        return (httpResponse.statusCode, data)
    }
    
    public static func MD5(from string: String) -> String {
        let data = string.data(using: .utf8)!
            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            data.withUnsafeBytes {
                _ = CC_MD5($0.baseAddress, CC_LONG(data.count), &digest)
            }
            return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    public static func SHA1(from string: String) -> String {
        let data = string.data(using: .utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
}
