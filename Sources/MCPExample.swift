//
//  MPCExample.swift
//  SwiftEverywhere
//
//  Created by Bill Gestrich on 12/2/24.
//

import Foundation
@preconcurrency import SwiftyGPIO

struct MPCExample: Sendable {
    let boardType: SupportedBoard
    let ledGPIO: GPIO
    init?(boardType: SupportedBoard) {
        self.boardType = boardType
        let gpios = SwiftyGPIO.GPIOs(for: boardType)
        guard let ledGPIO = gpios[.P21] else {
            print("Could not read GPIO")
            return nil
        }
        ledGPIO.direction = .OUT
        self.ledGPIO = ledGPIO
    }

    func start() {
        let timer = Timer(
            timeInterval: 0.2, repeats: true,
            block: { timer in
                printValues()
            })
        RunLoop.main.add(timer, forMode: .default)
        montitorButtonPress()
    }

    func printValues() {
                // SPI
        let voltage0Percent = getVoltage(channel: 0)
        let voltage1Percent = getVoltage(channel: 1)
        if voltage0Percent > 15 {
            setLight(on: true)
        } else {
            setLight(on: false)
        }

        print("\u{1B}[1A\u{1B}[KChannel0: \(voltage0Percent)%, Channel1: \(voltage1Percent)%")
    }

    func montitorButtonPress() {
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

    func getVoltage(channel: UInt8) -> Int {
        let voltage = 3.2
        let voltage0 = self.mcpVoltage(
            outputCode: self.mcpReadData(a2dChannel: channel), voltageReference: voltage)
        return abs(Int(voltage0 / voltage * 100) - 100)
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
        return Double(outputCode) * voltageReference / 1024.0
    }
}
