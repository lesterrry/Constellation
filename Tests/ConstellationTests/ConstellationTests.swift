//
//  ConstellationTests.swift
//  Constellation
//
//  Created by aydar.media on 23.07.2023.
//

import XCTest
import OSLog
@testable import Constellation

#warning("All these tests are meant to run one-by-one, not altogether")

final class ConstellationTests: XCTestCase {
    func testPlainAuth() async {
        guard let appId = ProcessInfo.processInfo.environment["SL_APPID"],
              let appSecret = ProcessInfo.processInfo.environment["SL_APPSECRET"],
              let userLogin = ProcessInfo.processInfo.environment["SL_USERLOGIN"],
              let userPassword = ProcessInfo.processInfo.environment["SL_USERPASSWORD"]
        else { XCTFail("One or more env vars not set"); return }

        var client = ApiClient(appId: appId, appSecret: appSecret, userLogin: userLogin, userPassword: userPassword)
        var smsCode: String? = nil
        
        let group = DispatchGroup()
        var shouldStop = false
        func stop() { shouldStop = true }
        
        for _ in 1...2 {
            if shouldStop { break }
            group.enter()
            
            await client.auth(smsCode: smsCode) { result in
                switch result {
                case .success(let token):
                    os_log("Success: \(token)")
                    XCTAssert(token.count > 1)
                    shouldStop = true
                case .failure(let error):
                    switch error {
                    case ApiClient.AuthError.secondFactorRequired:
                        guard smsCode == nil else { XCTFail("2nd factor asked with sms code already present"); shouldStop = true; break }
                        os_log("2FA CODE REQUIRED")
                        os_log("Enter code: ")
                        if let code = readLine() {
                            smsCode = code
                            os_log("Continuing...")
                        } else {
                            XCTFail("Failed to read user input"); shouldStop = true
                        }
                    default:
                        XCTFail("Error: \(error)"); shouldStop = true
                    }
                }
                group.leave()
            }
            group.wait()
        }
        XCTAssertNotNil(client.authorizedUser)
    }
    
    func testKeychain() {
        let token = "123:456"
        let account = "TEST"
        
        XCTAssertNoThrow(try Keychain.saveToken(token, account: account))
        
        var recovered: String? = nil
        XCTAssertNoThrow(recovered = try Keychain.getToken(account: account))
        
        XCTAssertEqual(token, recovered)
        
        XCTAssertNoThrow(try Keychain.deleteToken(account: account))
        
        XCTAssertThrowsError(try Keychain.getToken(account: account))
    }
    
    // Note: this test assumes the user token is already stored in keychain
    func testBasicRequest() async {
        guard let appId = ProcessInfo.processInfo.environment["SL_APPID"],
              let appSecret = ProcessInfo.processInfo.environment["SL_APPSECRET"],
              let userLogin = ProcessInfo.processInfo.environment["SL_USERLOGIN"],
              let userPassword = ProcessInfo.processInfo.environment["SL_USERPASSWORD"]
        else { XCTFail("One or more env vars not set"); return }

        var client = ApiClient(appId: appId, appSecret: appSecret, userLogin: userLogin, userPassword: userPassword)
        
        XCTAssert(client.hasUserToken)
        
        await client.auth() { result in
            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
                return
            }
        }
        
        XCTAssertNotNil(client.authorizedUser)
        
        let deviceId: Int
        
        do {
            let devices = try await client.getDevicesForCurrentUser()

            XCTAssertNotNil(devices)

            os_log("Success: \(devices)")
            
            deviceId = devices[0].deviceId
        } catch {
            XCTFail("Error: \(error)"); return
        }
        
        
        do {
            let data = try await client.getDeviceData(for: deviceId)
            
            os_log("Success: \(data)")
            
            if case ApiResponse.Data.device(let device) = data {
                XCTAssertNotNil(device)
                if let state = device.state, let door = state.door {
                    os_log("Doors are \(door ? "open" : "closed")")
                } else {
                    os_log("No information about door state")
                }
            } else {
                XCTFail("Data instance is not a Device")
            }

        } catch {
            XCTFail("Error: \(error)")
        }
    }
}
