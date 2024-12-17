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
    
    public func getAnalogReading(channel: Int) async throws -> SECommon.AnalogReading {
        guard let result = try await dynamoStore.getLatest(type: DynamoAnalogReading.self)?.toReading() else {
            throw LambdaDemoError.noAnalogReading
        }
        return result
    }
    
    public func getAnalogReadings(channel: Int, range: SECommon.DateRangeRequest) async throws -> [SECommon.AnalogReading] {
        return try await dynamoStore.getItems(type: DynamoAnalogReading.self, oldestDate: range.startDate, latestDate: range.endDate).compactMap { try? $0.toReading() }
    }
    
    public func updateAnalogReading(reading: SECommon.AnalogReading) async throws -> SECommon.AnalogReading {
        return try await dynamoStore.store(type: DynamoAnalogReading.self, item: DynamoAnalogReading(reading: reading)).toReading()
    }
    
    public func getHost() async throws -> SECommon.Host {
        guard let result = try await dynamoStore.getLatest(type: DynamoHost.self)?.toHost() else {
            throw LambdaDemoError.missingHost
        }
        return result
    }
    
    public func postHost(_ host: SECommon.Host) async throws -> SECommon.Host {
        let dynamoHost = DynamoHost(host: host)
        return try await dynamoStore.store(type: DynamoHost.self, item: dynamoHost).toHost()
    }
    
    public func getLightSensorReading() async throws -> LightSensorReading {
        guard let result = try await dynamoStore.getLatest(type: DynamoLightSensorReading.self)?.toReading() else {
            throw LambdaDemoError.noLightSensorReading
        }
        return result
    }
    
    public func getLightSensorReadings(range: SECommon.DateRangeRequest) async throws -> [LightSensorReading] {
        return try await dynamoStore.getItems(type: DynamoLightSensorReading.self, oldestDate: range.startDate, latestDate: range.endDate).compactMap { try? $0.toReading() }
    }
    
    public func updateLightSensorReading(_ reading: LightSensorReading) async throws -> SECommon.LightSensorReading {
        return try await dynamoStore.store(type: DynamoLightSensorReading.self, item: DynamoLightSensorReading(reading: reading)).toReading()
    }
    
    public func getLEDState() async throws -> LEDState {
        return try await piClientSource().getLEDState()
    }
    
    public func updateLEDState(_ state: LEDState) async throws -> LEDState {
        return try await piClientSource().updateLEDState(state)
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
        case noLightSensorReading
    }
    
}
