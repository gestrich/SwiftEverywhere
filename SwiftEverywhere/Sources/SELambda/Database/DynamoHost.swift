//
//  DynamoHost.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/13/24.
//

import Foundation
import SECommon
import SotoDynamoDB

public struct DynamoHost: Codable {
    
    public let ipAddress: String
    public let port: Int
    
    // These must match here and in the AWS SAM template.yml too
    public let uploadDate: String // Must be String type (aws RANGE) for sorting with this
    public let partition: String
    
    public init(host: SECommon.Host){
        self.ipAddress = host.ipAddress
        self.port = host.port
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        self.uploadDate = formatter.string(from: Date())
        self.partition = Self.createPartition()
    }
    
    func toHost() throws -> SECommon.Host {
        return Host(ipAddress: ipAddress, port: port)
    }
    
    static func searchRequest() -> DynamoSearchRequest {
        return DynamoSearchRequest(partition: Self.createPartition())
    }
    
    static func createPartition() -> String {
        return "Host"
    }
    
    enum DynamoHostError: Error {
        case invalidUploadDate
    }
}
