//
//  ConstellationTests.swift
//  Constellation
//
//  Created by aydar.media on 23.07.2023.
//

import XCTest
@testable import Constellation

final class ConstellationTests: XCTestCase {
    func testAuth() async {
        guard let appID = ProcessInfo.processInfo.environment["SL_APPID"],
              let appSecret = ProcessInfo.processInfo.environment["SL_SECRET"]
        else { XCTFail("One or more env vars not set"); return }

        let client = ApiClient(appID: appID, secret: appSecret)
        await client.auth { result in
//            print(result)
        }
//        XCTAssertEqual(Constellation().text, "Hello, World!")
    }
}
