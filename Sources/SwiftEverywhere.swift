// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import SwiftyGPIO

@main
struct SwiftEverywhere {
    static func main() throws -> Void {
        Self.montitorButtonPress()
        Self.setupBlink()
        RunLoop.main.run()
    }

    static func setupBlink() {
        let timer = Timer(timeInterval: 1, repeats: true, block: { timer in
            let gpios = SwiftyGPIO.GPIOs(for: boardType)
            guard let gpLED = gpios[.P21] else {
                print("Could not read GPIO")
                return
            }
            setLED(on: gpLED.value == 0)
        })
        RunLoop.main.add(timer, forMode: .default)
    }

    static func montitorButtonPress() {
        let gpios = SwiftyGPIO.GPIOs(for: boardType)
        guard let gpInput = gpios[.P26] else {
            print("Could not read GPIO")
            return
        }
        gpInput.pull = .down
        gpInput.direction = .IN
        gpInput.onChange{ gpio in
            print("Value Changed:" + String(gpio.value))         
        }
    }

    static func setLED(on: Bool) {
        let gpios = SwiftyGPIO.GPIOs(for: boardType)
        guard let gp = gpios[.P21] else {
            print("Could not read GPIO")
            return
        }

        gp.direction = .OUT
        gp.value = on ? 1 : 0
    }

    static var boardType: SupportedBoard {
        return .RaspberryPi4_2024
    }
}
