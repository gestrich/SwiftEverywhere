//
//  SwiftServerApp.swift
//
//
//  Created by Bill Gestrich on 12/9/23.
//

import Foundation
import SECommon
import SotoSNS

public struct SwiftServerApp: SwiftEverywhereAPI {
    public typealias PiClientSource = () async throws -> SwiftEverywhereAPI
    
    let cloudDataStore: CloudDataStore?
    let piClientSource: () async throws -> SwiftEverywhereAPI
    let dynamoStore: DynamoStoreService
    let sns: SNS
    let s3FileKey = "hello-world.text"
    
    public init(
        cloudDataStore: CloudDataStore? = nil,
        piClientSource: @escaping PiClientSource,
        dynamoStore: DynamoStoreService,
        sns: SNS
    ) {
        self.cloudDataStore = cloudDataStore
        self.piClientSource = piClientSource
        self.dynamoStore = dynamoStore
        self.sns = sns
    }
    
    // MARK: AnalogReading
    
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
    
    // MARK: DeviceToken
    
    public func updateDeviceToken(_ token: SECommon.DeviceToken) async throws {
        // TODO: Define in a parameter store and support both sandbox and production
        let applicationARN = "arn:aws:sns:us-east-1:767387487465:app/APNS_SANDBOX/iOSPushNotificationPlatform"
        let input = SNS.CreatePlatformEndpointInput(
            customUserData: token.deviceName,
            platformApplicationArn: applicationARN,
            token: token.token
        )
        let snsEndpointResult = try await sns.createPlatformEndpoint(input)
        guard let endpointArn = snsEndpointResult.endpointArn else {
            return
        }
        _ = try await dynamoStore.store(item: DynamoDeviceToken(deviceToken: token, endpointARN: endpointArn))
    }
    
    func sendAPNS(title: String, subtitle: String, message: String) async throws {
        let arn = try await dynamoStore.getLatest(searchRequest: DynamoDeviceToken.searchRequest())?.endpointARN
        let publishInput = SNS.PublishInput(message: """
        {"aps":{"alert":{"title":\(title),"subtitle":"\(subtitle)","body":"\(message)"}}}
        """, targetArn: arn)
        
        try await sns.publish(publishInput)
    }
    
    // DigitalValue
    
    public func getDigitalOutput(channel: Int) async throws -> DigitalValue {
        return try await piClientSource().getDigitalOutput(channel: channel)
    }
    
    public func updateDigitalOutput(_ state: DigitalValue) async throws -> DigitalValue {
        return try await piClientSource().updateDigitalOutput(state)
    }
    
    // MARK: Host
    
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
