//
//  File.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/16/24.
//

import Foundation
import SECommon
import SotoDynamoDB

public struct DynamoAnalogReading: Codable {
    public let channel: Int
    public let value: Double
    
    // These must match here and in the AWS SAM template.yml too
    public let uploadDate: String // Must be String type (aws RANGE) for sorting with this
    public let partition: String
    
    public init(reading: AnalogReading){
        self.channel = reading.channel
        self.value = reading.value
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        self.uploadDate = formatter.string(from: reading.uploadDate)
        self.partition = DynamoAnalogReading.partition
    }
    
    func toReading() throws -> AnalogReading {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        guard let date = formatter.date(from: uploadDate) else {
            throw DynamoAnalogReadingError.invalidUploadDate
        }
        return AnalogReading(channel: channel, uploadDate: date, value: value)
    }
    
    private enum DynamoAnalogReadingError: Error {
        case invalidUploadDate
    }
}
 
extension DynamoAnalogReading: DynamoPartitioned {
    static let sortKey = "uploadDate" // Name of property above
    static let partitionKey = "partition" // Name of property above
    static let partition: String = "AnalogReading"
}
