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
        
        // Getting all devices
        
        let deviceId: Int
        
        let devices = await client.getDevicesForCurrentUser() { result in
            switch result {
            case .success(let devices):
                os_log("Success: \(devices)")
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        
        XCTAssertNotNil(devices)
        
        deviceId = devices![0].deviceId
        
        // Getting device info
        
        let data = await client.getDeviceData(for: deviceId) { result in
            switch result {
            case .success(let device):
                os_log("Success: \(device)")
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        
        XCTAssertNotNil(data)
        
        if case ApiResponse.Data.device(let device) = data! {
            XCTAssertNotNil(device)
            if let state = device.state, let door = state.door {
                os_log("Doors are \(door ? "open" : "closed")")
            } else {
                os_log("No information about door state")
            }
        } else {
            XCTFail("Data instance is not a Device")
        }
    }
    
    func testHonk() async {
        guard let appId = ProcessInfo.processInfo.environment["SL_APPID"],
              let appSecret = ProcessInfo.processInfo.environment["SL_APPSECRET"],
              let deviceId = ProcessInfo.processInfo.environment["SL_DEVICEID"]
        else { XCTFail("One or more env vars not set"); return }

        var client = ApiClient(appId: appId, appSecret: appSecret)
        
        XCTAssert(client.hasUserToken)
        
        await client.auth() { result in
            if case .failure(let error) = result {
                XCTFail(String(describing: error))
                return
            }
        }
        
        XCTAssertNotNil(client.authorizedUser)
        
        // Time to honk
        
        await client.runCommand(.honk, on: Int(deviceId)!) { result in
            switch result {
            case .success():
                os_log("Success")
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
    }
}
