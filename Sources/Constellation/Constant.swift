//
//  File.swift
//  
//
//  Created by aydar.media on 24.07.2023.
//

import Foundation

struct Constant {
    struct Endpoints {
        public static func getCode(appID: String, secret: String) -> URL {
            return URL(string: "https://id.starline.ru/apiV3/application/getCode?appId=\(appID)&secret=\(secret)")!
        }
    }
}
