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
        case .reverse0To100Percent:
            return (voltage.rawValue - reading) / voltage.rawValue * 100
        case .temperatureTMP36Fahrenheit:
            let voltageReference = 3.3
            // Step 4: Convert temperatures
            let temperatureC = (voltage.rawValue - 0.5) * 100
            let temperatureF = (temperatureC * 9.0 / 5.0) + 32.0
            return temperatureF
        }
    }
    
    public func displayableLabel(reading: Double) -> String {
        switch valueInterpretation {
        case .reverse0To100Percent:
            return String(formatToTwoDecimals(displayableValue(reading: reading))) + "%"
        case .temperatureTMP36Fahrenheit:
            return String(formatToTwoDecimals(displayableValue(reading: reading))) + "°F"
        }
    }
    
    func formatToTwoDecimals(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        return formatter.string(for: number) ?? "N/A"
    }
}

public enum AnalogReadingValueInterpretation: Codable, Equatable, Sendable {
    case reverse0To100Percent
    case temperatureTMP36Fahrenheit
}
