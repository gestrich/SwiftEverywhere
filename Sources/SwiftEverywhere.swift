// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import SwiftyGPIO

@main
struct SwiftEverywhere {
    static func main() async throws -> Void {
        Self.readGPIO()
        try await Task.self .sleep(for: .seconds(1))
        Self.setGPIO()
        Self.readGPIO()
    }
    
    static func readGPIO() {
        let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi4)
        guard let gp = gpios[.P21] else {
            print("Could not read GPIO")
            return
        }
        print(gp.value)
    }
    
    static func setGPIO() {
        let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi4)
        guard let gp = gpios[.P21] else {
            print("Could not read GPIO")
            return
        }
	gp.direction = .OUT
        gp.value =  1
    }
}
