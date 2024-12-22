//
//  AnalogValue.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/16/24.
//

import Foundation

public struct AnalogValue: Codable, Equatable, Sendable, Hashable {
    public let channel: Int
    public let uploadDate: Date
    public let value: Double
    
    public init(channel: Int, uploadDate: Date, value: Double) {
        self.uploadDate = uploadDate
        self.value = value
        self.channel = channel
    }
    
    public static func == (lhs: AnalogValue, rhs: AnalogValue) -> Bool {
        lhs.channel == rhs.channel && lhs.uploadDate == rhs.uploadDate && lhs.value == rhs.value
    }
}
