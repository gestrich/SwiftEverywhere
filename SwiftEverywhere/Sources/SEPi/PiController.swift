//
//  PiController.swift
//  SwiftEverywherePi
//
//  Created by Bill Gestrich on 12/2/24.
//

import Foundation
import SECommon
@preconcurrency import SwiftyGPIO

public struct PiController: Sendable {
    let boardType: SupportedBoard
    let ledGPIO: GPIO
    
    public typealias PollingScheduler = @Sendable (_ initialDelay: TimeInterval, _ delay: TimeInterval, _ task: @escaping @Sendable () -> Void) -> Void
    let pollingScheduler: PollingScheduler

    public init?(boardType: SupportedBoard, pollingScheduler: @escaping PollingScheduler) {
        self.boardType = boardType
        let gpios = SwiftyGPIO.GPIOs(for: boardType)
        guard let ledGPIO = gpios[.P21] else {
            print("Could not read GPIO")
            return nil
        }
        ledGPIO.direction = .OUT
        self.ledGPIO = ledGPIO
        self.pollingScheduler = pollingScheduler
    }

    public func start() {
        pollingScheduler(1.0, 1.0) {
            printValues()
        }
        monitorButtonPress()
    }

    func printValues() {
        // SPI
        let temp = getTemperatureFahrenheit(channel: 2)
        print("\u{1B}[1A\u{1B}[KChannel1: \(channel1Reading())%. Temp: \(temp)F")
    }
    
    func channel1Reading() -> Double {
        return getVoltagePercentage(channel: 1)
    }

    func monitorButtonPress() {
        let gpios = SwiftyGPIO.GPIOs(for: boardType)
        guard let gpInput = gpios[.P26] else {
            print("Could not read GPIO")
            return
        }
        gpInput.pull = .down
        gpInput.direction = .IN
        gpInput.onFalling { gpio in
            print("Button Pressed Down")
        }
    }

    func getVoltagePercentage(channel: UInt8) -> Double {
        let voltageReference = 3.3  // Reference voltage
        let signalVoltage = self.mcpVoltage(
            outputCode: self.mcpReadData(a2dChannel: channel),
            voltageReference: voltageReference
        )
        let percentage = (signalVoltage / voltageReference) * 100
        print("Signal Voltage: \(signalVoltage) V, Percentage: \(percentage)%")
        return percentage
    }

    func getTemperatureFahrenheit(channel: UInt8) -> Double {
        // Step 1: Read voltage from the sensor
        let voltage = self.mcpVoltage(
            outputCode: self.mcpReadData(a2dChannel: channel),
            voltageReference: 3.3  // Ensure this matches VREF
        )
        
        // Check if the voltage is within range
        if voltage >= 3.3 || voltage <= 0 {
            print("Voltage out of range: \(voltage)")
            return Double.nan
        }
        print("Voltage: \(voltage) V") // Debugging
        
        // Step 2: Calculate thermistor resistance
        let fixedResistor = 10_000.0  // 10kΩ fixed resistor
        let thermistorResistance = fixedResistor * ((3.3 / voltage) - 1.0)
        if thermistorResistance < 0 || thermistorResistance.isNaN {
            print("Invalid thermistor resistance: \(thermistorResistance)")
            return Double.nan
        }
        print("Thermistor Resistance: \(thermistorResistance) Ω") // Debugging
        
        // Step 3: Apply the Steinhart-Hart equation
        let nominalTemperatureK = 298.15  // Nominal temperature (25°C in Kelvin)
        let betaCoefficient = 3950.0      // Beta value for the thermistor
        let nominalResistance = 100_000.0 // 100kΩ at 25°C
        
        let temperatureK = 1.0 / (
            (1.0 / nominalTemperatureK) +
            (1.0 / betaCoefficient) * log(thermistorResistance / nominalResistance)
        )
        if temperatureK.isNaN || temperatureK <= 0 {
            print("Invalid temperature calculation: \(temperatureK)")
            return Double.nan
        }
        print("Temperature (Kelvin): \(temperatureK) K") // Debugging
        
        // Step 4: Convert Kelvin to Fahrenheit
        let temperatureF = (temperatureK - 273.15) * 9.0 / 5.0 + 32.0
        print("Temperature (Fahrenheit): \(temperatureF) °F") // Debugging
        
        return temperatureF
    }


    func setLight(on: Bool) {
        ledGPIO.value = on ? 1 : 0
    }

    func mcpReadData(a2dChannel: CUnsignedChar) -> UInt64 {
        // TODO: hardwareSPIs returned nil when using the Raspberry 4 board type here.
        let spis = SwiftyGPIO.hardwareSPIs(for: .RaspberryPiPlusZero)!
        let spi = spis[0]

        var outData = [UInt8]()
        outData.append(1)  //  first byte transmitted -> start bit
        outData.append(0b10000000 | (((a2dChannel & 7) << 4)))  // second byte transmitted -> (SGL/DIF = 1, D2=D1=D0=0)

        // Use mask to get ada channel between 0 - 7
        //   00000111
        // & 00000001
        //   00000001

        // Move channel to upper 4 bits
        //   00000001
        //<< 4
        //   00010000

        // Set leftmost bit to 1 and next 3 bits to ADA channel.
        //   10000000
        // | 00010000
        //   10010000
        outData.append(0)  // third byte transmitted....don't care

        let inData = spi.sendDataAndRead(outData, frequencyHz: 500_000)
        var a2dVal: UInt64 = 0
        a2dVal = UInt64(inData[1]) << 8  //merge data[1] & data[2] to get result
        a2dVal |= UInt64(inData[2])
        return a2dVal
    }

    func mcpVoltage(outputCode: UInt64, voltageReference: Double) -> Double {
        guard outputCode <= 1023 else {
            print("Invalid ADC output: \(outputCode)")
            return Double.nan
        }
        return Double(outputCode) * voltageReference / 1023.0
    }
}

extension PiController: PiClientAPI {
    
    public func getAnalogReading(channel: Int) async throws -> SECommon.AnalogReading {
        let voltage = getVoltagePercentage(channel: UInt8(channel))
        return AnalogReading(channel: channel, uploadDate: Date(), value: Double(voltage))
    }
    
    public func getAnalogReadings(channel: Int, range: SECommon.DateRangeRequest) async throws -> [SECommon.AnalogReading] {
        return try await [getAnalogReading(channel: channel)]
    }
    
    public func updateAnalogReading(reading: SECommon.AnalogReading) async throws -> SECommon.AnalogReading {
        throw RoutesError.unsupportedMethod
    }
    
    public func getHost() async throws -> SECommon.Host {
        throw RoutesError.unsupportedMethod
    }
    
    public func postHost(_ host: SECommon.Host) async throws -> SECommon.Host {
        throw RoutesError.unsupportedMethod
    }
    
    public func getLEDState() async throws -> SECommon.LEDState {
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        guard let ledGPIO = gpios[.P21] else {
            print("Could not read GPIO")
            throw RoutesError.gpioError
        }
        ledGPIO.direction = .OUT
        return LEDState(on: ledGPIO.value == 1 ? true : false)
    }
    
    public func updateLEDState(_ state: LEDState) async throws -> LEDState {
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        guard let ledGPIO = gpios[.P21] else {
            print("Could not read GPIO")
            throw RoutesError.gpioError
        }
        ledGPIO.direction = .OUT
        ledGPIO.value = state.on ? 1 : 0
        return state
    }
}

private enum RoutesError: LocalizedError {
    case unexpectedBody
    case gpioError
    case unsupportedMethod
}
