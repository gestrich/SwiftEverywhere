//
//  AnalogReading.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/16/24.
//

import Foundation

public struct AnalogReading: Codable, Equatable, Sendable {
    public let channel: Int
    public let uploadDate: Date
    public let value: Double
    
    public init(channel: Int, uploadDate: Date, value: Double) {
        self.uploadDate = uploadDate
        self.value = value
        self.channel = channel
    }
}
