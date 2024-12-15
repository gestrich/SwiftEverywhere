//
//  LightSensorReading.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/14/24.
//

import Foundation

public struct LightSensorReading: Codable, Equatable, Sendable {
    public let uploadDate: Date
    public let value: Double
    
    public init(uploadDate: Date, value: Double) {
        self.uploadDate = uploadDate
        self.value = value
    }
}
