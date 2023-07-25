//
//  Data.swift
//  
//
//  Created by aydar.media on 24.07.2023.
//

import Foundation

struct SlidResponse: Decodable {
    struct Desc: Decodable {
        let code: String?
        let token: String?
        let message: String?
        let user_token: String?
        let realplexor_id: String?
    }
    
    let state: Int
    let desc: Desc
}

struct ApiResponse: Decodable {
    let code: Int
    let codestring: String
    let realplexor_id: String?
}
