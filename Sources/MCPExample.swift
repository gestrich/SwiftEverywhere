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
    //Repeat Method
    func repeatWithInterval(interval: UInt32, block:@escaping @Sendable () -> Void ){
        let queue = DispatchQueue.global()
        queue.async {
            block()
            sleep(interval)
            self.repeatWithInterval(interval: interval, block: block)
        }
    }
    
    func mcpReadData(a2dChannel: CUnsignedChar) -> UInt64 {
        let spis = SwiftyGPIO.hardwareSPIs(for:.RaspberryPiPlusZero)!
        let spi = spis[0]
        
        var outData = [UInt8]()
        outData.append(1) //  first byte transmitted -> start bit
        outData.append(0b10000000 | ( ((a2dChannel & 7) << 4))); // second byte transmitted -> (SGL/DIF = 1, D2=D1=D0=0)
        
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
        outData.append(0); // third byte transmitted....don't care
        
        let inData = spi.sendDataAndRead(outData, frequencyHz: 500_000)
        var a2dVal: UInt64 = 0
        a2dVal = UInt64(inData[1]) << 8 //merge data[1] & data[2] to get result
        a2dVal |=  UInt64(inData[2]);
        return a2dVal
    }
    
    func mcpVoltage(outputCode: UInt64, voltageReference: Double) -> Double {
        return Double(outputCode) * voltageReference / 1024.0
    }

    func start() {
        repeatWithInterval(interval: 1) { [self] in
            print("Raspberry Pi Tests Beginning")
            
            //Reset from command line with `gpio -g mode 17 out`
            let gpios = SwiftyGPIO.GPIOs(for: boardType)
            guard let gpOut = gpios[.P17] else {
                print("Could not read GPIO")
                return
            }
            
            gpOut.direction = .OUT
            
            //var gpIn = GPIO(name: "P17",id: 17)
            
            //gpIn.direction = .IN
            
            //gpIn.onRaising{
            //    gpio in
            //    print("Transition to 1, current value:" + String(gpio.value))
            //}
            
            // var turnOn = false
            //LED
            let currentValue = gpOut.value
            let newValue = (currentValue == 1) ? 0 : 1
            gpOut.value = newValue
            //print("Changing the value.")
            
            //SPI
            let voltage = 3.2
            let voltage0 = self.mcpVoltage(outputCode: self.mcpReadData(a2dChannel: 0), voltageReference: voltage)
            let voltage1 = mcpVoltage(outputCode: mcpReadData(a2dChannel: 1), voltageReference: voltage)
            let voltage0Percent = abs(Int(voltage0 / voltage * 100) - 100)
            let voltage1Percent = abs(Int(voltage1 / voltage * 100) - 100)
            print("\u{1B}[1A\u{1B}[KLight: \(voltage0Percent)% Temp: \(voltage1Percent)%")
        }
        
        while true {
            
        }
    }
    
}
