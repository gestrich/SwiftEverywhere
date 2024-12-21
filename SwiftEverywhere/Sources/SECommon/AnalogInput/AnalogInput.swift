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
    public let typicalRange: ClosedRange<Double>
    public let valueInterpretation :AnalogReadingValueInterpretation
    
    public func displayableValue(reading: Double) -> Double {
        switch valueInterpretation {
        case .reverse0To100Percent:
            return (voltage.rawValue - reading) / voltage.rawValue * 100
        case .temperatureTMP36Fahrenheit:
            let voltageReference = 3.3
            let voltageAt0C = 0.5 // TMP 36 has 0.5 at 0C so we need to offset.
            let temperatureC = (reading - voltageAt0C) * 100
            let temperatureF = (temperatureC * 9.0 / 5.0) + 32.0
            return temperatureF
        }
    }
    
    public func displayableLabel(reading: Double) -> String {
        switch valueInterpretation {
        case .reverse0To100Percent:
            return String(format(displayableValue(reading: reading), decimalCount: 2)) + "%"
        case .temperatureTMP36Fahrenheit:
            return String(format(displayableValue(reading: reading), decimalCount: 1)) + "°F"
        }
    }
    
    func format(_ number: Double, decimalCount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalCount
        formatter.maximumFractionDigits = decimalCount

        return formatter.string(for: number) ?? "N/A"
    }
}

public enum AnalogReadingValueInterpretation: Codable, Equatable, Sendable {
    case reverse0To100Percent
    case temperatureTMP36Fahrenheit
}
