//
//  Security.swift
//  
//
//  Created by aydar.media on 29.07.2023.
//

import Foundation
import Security

struct SecurityError: Error {
    var message: String?
}

struct KeychainEntity {
    public static let serviceName = "com.aydarmedia.constellation"
    public enum Account: String {
        case userToken = "USER_TOKEN"
    }
}

struct Keychain {
    public static func saveToken(_ token: String, account: String, service: String = KeychainEntity.serviceName) throws {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        
        // First, try to fetch an existing item
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {  // Existing item found, update it
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            try itemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        } else if status == errSecItemNotFound {  // Item not found, add a new one
            var newQuery = query
            newQuery[kSecValueData as String] = data
            try itemAdd(newQuery as CFDictionary)
        } else {
            throw SecurityError(message: "Failed with \(status) code")
        }
    }
    
    public static func getToken(account: String, service: String = KeychainEntity.serviceName) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue!
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            if let data = dataTypeRef as? Data, let token = String(data: data, encoding: .utf8) {
                return token
            } else {
                throw SecurityError(message: "Failed to read decode Keychain data")
            }
        } else {
            throw SecurityError(message: "Failed to read from Keychain")
        }
    }
    
    public static func deleteToken(account: String, service: String = KeychainEntity.serviceName) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != noErr {
            throw SecurityError(message: "Failed to remove from Keychain")
        }
    }
    
    
    private static func itemUpdate(_ query: CFDictionary, _ attributes: CFDictionary) throws {
        let status = SecItemUpdate(query, attributes)
        if status != noErr { throw SecurityError(message: "itemUpdate failed with \(status) code") }
    }
    
    private static func itemAdd(_ query: CFDictionary) throws {
        let status = SecItemAdd(query, nil)
        if status != noErr { throw SecurityError(message: "itemAdd failed with \(status) code") }
    }
    
}
