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
        let arns = try await self.allDeviceTokenARNs()
        if !arns.contains(endpointArn) {
            _ = try await dynamoStore.store(item: DynamoDeviceToken(deviceToken: token, endpointARN: endpointArn))
        }
    }
    
    private func allDeviceTokenARNs() async throws -> [String] {
        let arns = try await dynamoStore.getItems(
            searchRequest: DynamoDeviceToken.searchRequest(),
            oldestDate: Date().addingTimeInterval(-60 * 60 * 24 * 365),
            latestDate: Date()
        ).map {$0.endpointARN}
        return Array(Set(arns))
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
    
    //MARK PushNotification
    
    public func sendPushNotification(_ notification: SECommon.PushNotification) async throws {
        let arns = try await allDeviceTokenARNs()
        
        for arn in arns {
//            let publishInput = SNS.PublishInput(message: """
//            {"aps":{"alert":{"title":\(notification.title),"subtitle":"\(notification.subtitle)","body":"\(notification.message)"}}}
//            """, targetArn: arn)

            let publishInput = SNS.PublishInput(
                message: """
            {
            "default": "This is the default message which must be present when publishing a message to a topic. The default message will only be used if a message is not present for  one of the notification platforms.",     
            "APNS": "{\"aps\":{\"alert\": \"Check out these awesome deals!\",\"url\":\"www.amazon.com\"} }",
            "GCM": "{\"data\":{\"message\":\"Check out these awesome deals!\",\"url\":\"www.amazon.com\"}}",
            "ADM": "{\"data\":{\"message\":\"Check out these awesome deals!\",\"url\":\"www.amazon.com\"}}" 
            }
            """,
//                messageAttributes: [:
//                    "AWS.SNS.MOBILE.APNS.TOPIC":{"DataType":"String","StringValue":"com.amazon.mobile.messaging.myapp"},
//                    "AWS.SNS.MOBILE.APNS.PUSH_TYPE":{"DataType":"String","StringValue":"background"},
//                    "AWS.SNS.MOBILE.APNS.PRIORITY":{"DataType":"String","StringValue":"5"}}'
//                ],
//                messageStructure: "json",
                targetArn: arn
            )
            try await sns.publish(publishInput)
        }
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
