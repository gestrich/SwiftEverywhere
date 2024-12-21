//
//  PiHardwareConfiguration.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/19/24.
//

import Foundation

public struct PiHardwareConfiguration: Sendable {
    public let sensorConfigurations: [AnalogSensorConfiguration]
    
    public init() {
        self.sensorConfigurations = [
            AnalogSensorConfiguration(
                name: "Light",
                channel: 1,
                voltage: .v3_3,
                valueInterpretation: .reverse
            ),
            AnalogSensorConfiguration(
                name: "Temperature",
                channel: 2,
                voltage: .v3_3,
                valueInterpretation: .reverse
            ),
        ]
    }
}

public struct AnalogSensorConfiguration: Sendable {
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

public enum Voltage: Double, Sendable {
    case v3_3 = 3.3
    case v5_0 = 5.0
}
