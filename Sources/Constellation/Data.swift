//
//  Data.swift
//  
//
//  Created by aydar.media on 24.07.2023.
//

import Foundation

struct SlidResponse: Decodable {
    struct Desc: Decodable {
        let id: String?
        let code: String?
        let token: String?
        let message: String?
        let user_token: String?
        let realplexor_id: String?
    }
    
    let state: Int
    let desc: Desc
}

public struct ApiResponse: Decodable {
    public struct Device: Decodable {
        let device_id: Int
        let alias: String?
    }
    
    // TODO: Removed due to type mismatch across requests
    // let code: String
    let codestring: String
    
    let realplexor_id: String?
    let user_id: String?
    
    let devices: [Device]?
}
