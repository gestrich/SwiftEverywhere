//
//  Host.swift
//  HomeAPI
//
//  Created by Bill Gestrich on 11/28/24.
//

import Foundation

public struct Host: Codable {
    
    public let ipAddress: String
    
    // These must match here and in the AWS SAM template.yml too
    public let uploadDate: String // Must be String type (aws RANGE) for sorting with this
    public let partition: String
    
    public init(ipAddress: String, date: Date){
        self.ipAddress = ipAddress
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        self.uploadDate = formatter.string(from: Date())
        self.partition = Host.partition
    }
}
 
extension Host: DynamoPartitioned {
    static let sortKey = "uploadDate" // Name of property above
    static let partitionKey = "partition" // Name of property above
    static let partition: String = "Host"
}
