//
//  DynamoDeviceToken.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/22/24.
//

import Foundation
import SECommon
import SotoDynamoDB

public struct DynamoDeviceToken: Codable {
    
    public let token: String
    public let deviceName: String
    public let endpointARN: String
    
    // These must match here and in the AWS SAM template.yml too
    public let uploadDate: String // Must be String type (aws RANGE) for sorting with this
    public let partition: String
    
    public init(deviceToken: DeviceToken, endpointARN: String){
        self.token = deviceToken.token
        self.deviceName = deviceToken.deviceName
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        self.uploadDate = formatter.string(from: Date())
        self.partition = Self.createPartition()
        self.endpointARN = endpointARN
    }
    
    func toDeviceToken() throws -> DeviceToken {
        return DeviceToken(token: token, deviceName: deviceName)
    }
    
    static func searchRequest() -> DynamoSearchRequest<DynamoDeviceToken> {
        return DynamoSearchRequest(partition: Self.createPartition(), outputType: DynamoDeviceToken.self)
    }
    
    static func createPartition() -> String {
        return "DeviceToken"
    }
}
