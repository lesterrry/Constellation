//
//  Endpoints.swift
//  
//
//  Created by aydar.media on 24.07.2023.
//

import Foundation

struct Endpoints {
    struct Application {
        /// Getting application code
        public static func getCode(appID: String, appSecret: String) -> URL {
            return URL(string: "https://id.starline.ru/apiV3/application/getCode?appId=\(appID)&secret=\(appSecret)")!
        }
        /// Getting application token
        public static func getToken(appID: String, appSecret: String) -> URL {
            return URL(string: "https://id.starline.ru/apiV3/application/getToken?appId=\(appID)&secret=\(appSecret)")!
        }
    }
    struct User {
        /// Getting user token
        public static var login: URL {
            return URL(string: "https://id.starline.ru/apiV3/user/login")!
        }
    }
    struct Json {
        /// Getting SLNet token
        public static var login: URL {
            return URL(string: "https://developer.starline.ru/json/v2/auth.slid")!
        }
        /// Getting available devices
        public static func userInfo(userID: String) -> URL {
            return URL(string: "https://developer.starline.ru/json/v2/user/\(userID)/user_info")!
        }
    }
}
