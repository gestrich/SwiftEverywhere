//
//  SwiftServerApp.swift
//
//
//  Created by Bill Gestrich on 12/9/23.
//

import Foundation
import SECommon

public struct SwiftServerApp {
    
    public typealias PiClientSource = () async throws -> PiClientAPI
    
    let cloudDataStore: CloudDataStore?
    let piClientSource: () async throws -> PiClientAPI
    let s3FileKey = "hello-world.text"
    
    public init(cloudDataStore: CloudDataStore? = nil, piClientSource: @escaping PiClientSource) {
        self.cloudDataStore = cloudDataStore
        self.piClientSource = piClientSource
    }
    
    // MARK: Pi Service
    
    public func getLEDState() async throws -> LEDState {
        return try await piClientSource().getLEDState()
    }
    
    public func updateLEDState(_ state: LEDState) async throws -> LEDState {
        return try await piClientSource().updateLEDState(on: state.on)
    }
    
    //MARK: S3 Service
    
    public func uploadAndDownloadS3File() async throws -> String {
        guard let cloudDataStore else {
            throw LambdaDemoError.missingService(name: "s3Service")
        }
        let string = "Hello World! This data was written/read from S3."
        guard let data = string.data(using: .utf8) else {
            fatalError("Unexpected not to convert to data.")
        }
        try await cloudDataStore.uploadData(data, key: s3FileKey)
        guard let responseData = try await cloudDataStore.getData(key: s3FileKey) else {
            throw LambdaDemoError.unexpectedError(description: "Couldn't find S3 file")
        }
        
        guard let result = String(data: responseData, encoding: .utf8) else {
            throw LambdaDemoError.unexpectedError(description: "Can't convert Data to string")
        }
        return result
    }
    
    
    enum LambdaDemoError: LocalizedError {
        case missingService(name: String)
        case unexpectedError(description: String)
    }
    
}
