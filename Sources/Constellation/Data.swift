//
//  Data.swift
//  
//
//  Created by aydar.media on 24.07.2023.
//

import Foundation

struct GenericResponse: Decodable {
    struct Desc: Decodable {
        let code: String?
        let token: String?
        let message: String?
    }
    
    let state: Int
    let desc: Desc
}
