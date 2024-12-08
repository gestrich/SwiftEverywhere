// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import SEGPIO
import SwiftyGPIO

@main
struct SwiftEverywhere {
    static func main() throws -> Void {
        let boardType = SupportedBoard.RaspberryPi4_2024
        let mpcExample = MPCExample(
            boardType: boardType,
            pollingScheduler: { initialDelay, delay, task in
            let timer = Timer(
            timeInterval: 0.2, repeats: true,
            block: { timer in
                task()
            })
            RunLoop.main.add(timer, forMode: .default)
            }
        )
        mpcExample?.start()
        RunLoop.main.run()
    }
}
