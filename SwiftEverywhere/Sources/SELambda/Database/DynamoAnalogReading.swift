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
    
    public init(reading: AnalogValue){
        self.channel = reading.channel
        self.value = reading.value
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        self.uploadDate = formatter.string(from: reading.uploadDate)
        self.partition = Self.createPartition(channel: channel)
    }
    
    func toReading() throws -> AnalogValue {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        guard let date = formatter.date(from: uploadDate) else {
            throw DynamoAnalogReadingError.invalidUploadDate
        }
        return AnalogValue(channel: channel, uploadDate: date, value: value)
    }
    
    static func searchRequest(channel: Int) -> DynamoSearchRequest {
        return DynamoSearchRequest(partition: Self.createPartition(channel: channel))
    }
    
    static func createPartition(channel: Int) -> String {
        return "AnalogReading-\(channel)"
    }
    
    private enum DynamoAnalogReadingError: Error {
        case invalidUploadDate
    }
}

