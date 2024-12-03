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
        let boardType = SupportedBoard.RaspberryPi4_2024
        // try LEDExample(boardType: boardType).start()
        MPCExample(boardType: boardType).start()
        RunLoop.main.run()
    }
}
