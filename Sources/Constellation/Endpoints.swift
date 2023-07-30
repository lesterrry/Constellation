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
        public static func getCode(appId: String, appSecret: String) -> URL {
            return URL(string: "https://id.starline.ru/apiV3/application/getCode?appId=\(appId)&secret=\(appSecret)")!
        }
        /// Getting application token
        public static func getToken(appId: String, appSecret: String) -> URL {
            return URL(string: "https://id.starline.ru/apiV3/application/getToken?appId=\(appId)&secret=\(appSecret)")!
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
        public static func userInfo(userId: String) -> URL {
            return URL(string: "https://developer.starline.ru/json/v2/user/\(userId)/user_info")!
        }
        /// Getting device info
        public static func deviceData(deviceId: String) -> URL {
            return URL(string: "https://developer.starline.ru/json/v3/device/\(deviceId)/data")!
        }
    }
}
