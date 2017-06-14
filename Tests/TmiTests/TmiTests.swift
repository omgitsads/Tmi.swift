//
//  TmiTests.swift
//  Tmi
//
//  Created by Adam Holt on {TODAY}.
//  Copyright © 2017 Tmi. All rights reserved.
//

import Foundation
import XCTest
@testable import Tmi

class TmiTests: XCTestCase {
    func testExample() {
        let client = Client(username: "omgitsads", password: "***REMOVED***", channels: ["dotastarladder_en"])
        let expect = expectation(description: "Should authenticate")
        
        client.connect()
        
        
        waitForExpectations(timeout: 80) { (error) in
            if let err = error {
                XCTFail("Error occured: \(err.localizedDescription)")
            }
        }
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
}
