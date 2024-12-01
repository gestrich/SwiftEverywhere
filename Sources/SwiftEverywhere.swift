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
        print("Hello, world!")
    }
    
    func helloGPIO() {
        let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi3)
        let gp = gpios[.P2]!
        gp.value = .max
    }
}
