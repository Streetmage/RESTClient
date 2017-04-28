//
//  RESTClientTests.swift
//  RESTClientTests
//
//  Created by Evgeny Kubrakov on 07.03.17.
//  Copyright © 2017 Evgeny Kubrakov. All rights reserved.
//

import XCTest
@testable import RESTClient

class RESTClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let restClient = RESTClient(servicePath: "https://jsonplaceholder.typicode.com")
        RESTClient.isLoggingEnabled = true
        RESTClient.defaultClient = restClient
    }
    
    func testGetJSON() {
        let expectation = self.expectation(description: "get")
        RESTClient.defaultClient?.get(at: "/posts") { success, responseData, error in
            XCTAssertNil(error, (error?.localizedDescription)!)
            XCTAssertTrue(success)
            XCTAssertNotNil(responseData)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 30.0) { error in
            XCTAssertNil(error, (error?.localizedDescription)!)
        }
    }
    
    func testPostJSON() {
        let expectation = self.expectation(description: "post")
        RESTClient.defaultClient?.post(at: "/posts") { success, responseData, error in
            XCTAssertNil(error, (error?.localizedDescription)!)
            XCTAssertTrue(success)
            XCTAssertNotNil(responseData)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 30.0) { error in
            XCTAssertNil(error, (error?.localizedDescription)!)
        }
    }

    func testPutJSON() {
        let expectation = self.expectation(description: "put")
        RESTClient.defaultClient?.put(at: "/posts/1") { success, responseData, error in
            XCTAssertNil(error, (error?.localizedDescription)!)
            XCTAssertTrue(success)
            XCTAssertNotNil(responseData)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 30.0) { error in
            XCTAssertNil(error, (error?.localizedDescription)!)
        }
    }
    
    func testDeleteJSON() {
        let expectation = self.expectation(description: "delete")
        RESTClient.defaultClient?.delete(at: "/posts/1") { success, responseData, error in
            XCTAssertNil(error, (error?.localizedDescription)!)
            XCTAssertTrue(success)
            XCTAssertNotNil(responseData)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 30.0) { error in
            XCTAssertNil(error, (error?.localizedDescription)!)
        }
    }
    
    func testImageUpload() {
        let expectation = self.expectation(description: "image upload")
        let image = UIImage(named: "test.jpg", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let testParameters = ["test" : "test"]
        RESTClient.defaultClient?.upload(image: image!, to: "/posts", parameters: testParameters ) { success, responseData, error in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 30.0) { error in
            XCTAssertNil(error, (error?.localizedDescription)!)
        }
    }
    
    func testVideoUpload() {
        let expectation = self.expectation(description: "video upload")
        let length = 2048
        let bytes = [UInt32](repeating: 0, count: length).map { _ in arc4random() }
        let videoData = Data(bytes: bytes, count: length)
        let testParameters = ["test" : "test"]
        RESTClient.defaultClient?.upload(videoData: videoData, videoDataType: "mp4", to: "/posts", parameters: testParameters) { success, responseData, error in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 30.0) { error in
            XCTAssertNil(error, (error?.localizedDescription)!)
        }

    }
}
