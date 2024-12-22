//
//  SwiftServerApp.swift
//
//
//  Created by Bill Gestrich on 12/9/23.
//

import Foundation
import SECommon

public struct SwiftServerApp: PiClientAPI {
    public typealias PiClientSource = () async throws -> PiClientAPI
    
    let cloudDataStore: CloudDataStore?
    let piClientSource: () async throws -> PiClientAPI
    let dynamoStore: DynamoStoreService
    let s3FileKey = "hello-world.text"
    
    public init(
        cloudDataStore: CloudDataStore? = nil,
        piClientSource: @escaping PiClientSource,
        dynamoStore: DynamoStoreService
    ) {
        self.cloudDataStore = cloudDataStore
        self.piClientSource = piClientSource
        self.dynamoStore = dynamoStore
    }
    
    // MARK: Pi Service
    
    public func getAnalogReading(channel: Int) async throws -> SECommon.AnalogValue {
        return try await piClientSource().getAnalogReading(channel: channel)
    }
    
    public func getAnalogReadings(channel: Int, range: SECommon.DateRangeRequest) async throws -> [SECommon.AnalogValue] {
        let searchRequest = DynamoAnalogReading.searchRequest(channel: channel)
        return try await dynamoStore.getItems(searchRequest: searchRequest, oldestDate: range.startDate, latestDate: range.endDate).compactMap { try? $0.toReading() }
    }
    
    public func updateAnalogReading(reading: SECommon.AnalogValue) async throws -> SECommon.AnalogValue {
        return try await dynamoStore.store(item: DynamoAnalogReading(reading: reading)).toReading()
    }
    
    public func getHost() async throws -> SECommon.Host {
        let searchRequest = DynamoHost.searchRequest()
        guard let result = try await dynamoStore.getLatest(searchRequest: searchRequest)?.toHost() else {
            throw LambdaDemoError.missingHost
        }
        return result
    }
    
    public func postHost(_ host: SECommon.Host) async throws -> SECommon.Host {
        let dynamoHost = DynamoHost(host: host)
        return try await dynamoStore.store(item: dynamoHost).toHost()
    }
    
    public func getDigitalOutput(channel: Int) async throws -> DigitalValue {
        return try await piClientSource().getDigitalOutput(channel: channel)
    }
    
    public func updateDigitalReading(_ state: DigitalValue) async throws -> DigitalValue {
        return try await piClientSource().updateDigitalReading(state)
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
    
    
    private enum LambdaDemoError: LocalizedError {
        case missingService(name: String)
        case unexpectedError(description: String)
        case missingHost
        case noAnalogReading
    }
    
}
