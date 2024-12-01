// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import SwiftyGPIO

@main
struct SwiftEverywhere: ParsableCommand {
    mutating func run() throws {
        Self.readGPIO()
    }
    
    static func readGPIO() {
        let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi4)
        guard let gp = gpios[.P2] else {
            print("Could not read GPIO")
            return
        }
        print(gp.value)
    }
    
    static func setGPIO() {
        let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi4)
        let gp = gpios[.P2]!
        gp.value = .max
    }
}
