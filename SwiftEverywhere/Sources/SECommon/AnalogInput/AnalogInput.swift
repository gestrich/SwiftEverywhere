//
//  AnalogInput.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/21/24.
//

import Foundation

public struct AnalogInput: Sendable {
    public let name: String
    public let channel: Int
    public let voltage: Voltage
    public let valueInterpretation :AnalogReadingValueInterpretation
    
    public func displayableValue(reading: Double) -> Double {
        switch valueInterpretation {
        case .reverse:
            return (voltage.rawValue - reading) / voltage.rawValue * 100
        }
    }
}

public enum AnalogReadingValueInterpretation: Codable, Equatable, Sendable {
    case reverse
}
