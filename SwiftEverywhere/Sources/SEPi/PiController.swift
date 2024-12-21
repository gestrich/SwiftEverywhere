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
    
    public typealias PollingScheduler = @Sendable (_ initialDelay: TimeInterval, _ delay: TimeInterval, _ task: @escaping @Sendable () -> Void) -> Void
    let pollingScheduler: PollingScheduler

    public init?(boardType: SupportedBoard, pollingScheduler: @escaping PollingScheduler) {
        self.boardType = boardType
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
        return getVoltage(channel: 1)
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

    func getVoltage(channel: UInt8) -> Double {
        let voltageReference = 3.3  // Reference voltage
        return self.mcpVoltage(
            outputCode: self.mcpReadData(a2dChannel: channel),
            voltageReference: voltageReference
        )
    }
    
    func getTemperatureFahrenheit(channel: UInt8) -> Double {
        // Step 1: Read voltage from the sensor
        let voltage = self.mcpVoltage(
            outputCode: self.mcpReadData(a2dChannel: channel),
            voltageReference: 3.3  // Ensure this matches VREF
        )
        
        print("Voltage: \(voltage) V") // Debugging
        
        let voltageReference = 3.3
        
        // Step 4: Convert Kelvin to Celcius
        let temperatureC = (voltage - 0.5) * 100
        print("Temperature (Celcius): \(temperatureC) C") // Debugging
        
        // Step 4: Convert Kelvin to Fahrenheit
        let temperatureF = (temperatureC * 9.0 / 5.0) + 32.0
        print("Temperature (Fahrenheit): \(temperatureF) °F") // Debugging
        
        return temperatureF
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
    public func getAnalogReading(channel: Int) async throws -> SECommon.AnalogValue {
        let voltage = getVoltage(channel: UInt8(channel))
        return AnalogValue(channel: channel, uploadDate: Date(), value: Double(voltage))
    }
    
    public func getAnalogReadings(channel: Int, range: SECommon.DateRangeRequest) async throws -> [SECommon.AnalogValue] {
        return try await [getAnalogReading(channel: channel)]
    }
    
    public func updateAnalogReading(reading: SECommon.AnalogValue) async throws -> SECommon.AnalogValue {
        throw RoutesError.unsupportedMethod
    }
    
    public func getHost() async throws -> SECommon.Host {
        throw RoutesError.unsupportedMethod
    }
    
    public func postHost(_ host: SECommon.Host) async throws -> SECommon.Host {
        throw RoutesError.unsupportedMethod
    }
    
    public func getDigitalOutput(channel: Int) async throws -> DigitalValue {
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        guard let gpioNumber = GPIOName.gpioName(number: channel), let ledGPIO = gpios[gpioNumber] else {
            print("Could not read GPIO")
            throw RoutesError.gpioError
        }
        return DigitalValue(on: ledGPIO.value == 1 ? true : false, channel: channel)
    }
    
    func setupDigitalOutput(_ digitalOutput: DigitalOutput) async throws {
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        guard let gpioNumber = GPIOName.gpioName(number: digitalOutput.channel), let ledGPIO = gpios[gpioNumber] else {
            print("Could not read GPIO")
            throw RoutesError.gpioError
        }
        ledGPIO.direction = .OUT
    }

    public func updateDigitalReading(_ digitalOutput: DigitalValue) async throws -> DigitalValue {
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        guard let gpioNumber = GPIOName.gpioName(number: digitalOutput.channel), let ledGPIO = gpios[gpioNumber] else {
            print("Could not read GPIO")
            throw RoutesError.gpioError
        }
        ledGPIO.value = digitalOutput.on ? 1 : 0
        return digitalOutput
    }
}

private enum RoutesError: LocalizedError {
    case unexpectedBody
    case gpioError
    case unsupportedMethod
}

extension GPIOName {
    static func gpioName(number: Int) -> GPIOName? {
        return GPIOName(rawValue:"P\(number)")
    }
}
