//
//  ConstellationTests.swift
//  Constellation
//
//  Created by aydar.media on 23.07.2023.
//

import XCTest
import OSLog
@testable import Constellation

final class ConstellationTests: XCTestCase {
    func testPlainAuth() async {
        
        guard let appID = ProcessInfo.processInfo.environment["SL_APPID"],
              let appSecret = ProcessInfo.processInfo.environment["SL_APPSECRET"],
              let userLogin = ProcessInfo.processInfo.environment["SL_USERLOGIN"],
              let userPassword = ProcessInfo.processInfo.environment["SL_USERPASSWORD"]
        else { XCTFail("One or more env vars not set"); return }

        var client = ApiClient(appID: appID, appSecret: appSecret, userLogin: userLogin, userPassword: userPassword)
        var smsCode: String? = nil
        
        for _ in 1...2 {
            await client.auth(smsCode: smsCode) { result in
                switch result {
                case .success(let token):
                    os_log("Success: \(token)")
                    XCTAssert(token.count > 1)
                    return
                case .failure(let error):
                    switch error {
                    case ApiClient.AuthError.secondFactorRequired:
                        guard smsCode == nil else { XCTFail("2nd factor asked with sms code already present"); break }
                        os_log("2FA CODE REQUIRED")
                        os_log("Enter code: ")
                        if let code = readLine() {
                            smsCode = code
                            os_log("Continuing...")
                        } else {
                            XCTFail("Failed to read user input"); break
                        }
                    default:
                        XCTFail("Error: \(error)"); break
                    }
                }
            }
        }
        //        XCTAssertEqual(Constellation().text, "Hello, World!")
    }
}
