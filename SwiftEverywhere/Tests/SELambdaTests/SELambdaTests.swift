//
//  SwiftServerAppTests.swift
//  
//
//  Created by Bill Gestrich on 12/9/23.
//

import NIO
@testable import SELambda
import XCTest

final class SELambdaTests: XCTestCase {
    
    override func setUpWithError() throws {
    }
    
    override func tearDownWithError() throws {
    }
    
    func testS3UploadAndDownload() async throws {
//        let s3Service = MockCloudDataStore()
//        let app = SwiftServerApp(cloudDataStore: s3Service)
//        let result = try await app.uploadAndDownloadS3File()
//        XCTAssertEqual(result, "Hello World! This data was written/read from S3.")
    }
    
}

class MockCloudDataStore: CloudDataStore {
    var keysToData = [String: Data]()
    
    func getData(key: String) async throws -> Data? {
        return keysToData[key]
    }
    
    func uploadData(_ data: Data, key: String) async throws {
        keysToData[key] = data
    }
}
