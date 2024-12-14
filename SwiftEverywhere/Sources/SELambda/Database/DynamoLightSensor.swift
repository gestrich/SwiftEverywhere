//
//  DynamoLightSensorReading.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/14/24.
//

import Foundation
import SECommon
import SotoDynamoDB

public struct DynamoLightSensorReading: Codable {
    public let value: Double
    
    // These must match here and in the AWS SAM template.yml too
    public let uploadDate: String // Must be String type (aws RANGE) for sorting with this
    public let partition: String
    
    public init(reading: LightSensorReading){
        self.value = reading.value
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        self.uploadDate = formatter.string(from: reading.uploadDate)
        self.partition = DynamoHost.partition
    }
    
    func toReading() throws -> LightSensorReading {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        guard let date = formatter.date(from: uploadDate) else {
            throw DynamoLightSensorReadingError.invalidUploadDate
        }
        return LightSensorReading(uploadDate: date, value: value)
    }
    
    private enum DynamoLightSensorReadingError: Error {
        case invalidUploadDate
    }
}
 
extension DynamoLightSensorReading: DynamoPartitioned {
    static let sortKey = "uploadDate" // Name of property above
    static let partitionKey = "partition" // Name of property above
    static let partition: String = "LightSensorReading"
}
