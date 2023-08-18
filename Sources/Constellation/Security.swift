//
//  Security.swift
//  
//
//  Created by aydar.media on 29.07.2023.
//

struct KeychainEntity {
    public static let serviceName = "com.aydarmedia.constellation"
    public enum Account: String {
        case userToken = "USER_TOKEN"
    }
}
