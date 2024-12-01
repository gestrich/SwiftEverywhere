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
        
        let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi4)
            guard let gp = gpios[.P26] else {
                print("Could not read GPIO")
            return
        }
        gp.pull = .up
        gp.onChange{ gpio in
            // gpio.clearListeners()
            print("The value changed, current value:" + String(gpio.value))
        }  
        sleep(2)
        gpio.clearListeners()
        gp.pull = .up
            gp.onChange{ gpio in
            
            print("The value changed, current value:" + String(gpio.value))
        }  

        monitorGPIO(gp: gp)
        RunLoop.main.run()
        while true {
    print("GPIO.value=\(gp.value)")
}
        // while true {
            // Self.setGPIO(on: true)
            // try await Task.self .sleep(for: .seconds(2))
            // Self.setGPIO(on: false)
            // try await Task.self .sleep(for: .seconds(2))
        // }
    }

    static func monitorGPIO(gp: GPIO) {
        print("Montitoring Beginning")
        print("Direction = \(gp.direction)")
        gp.direction = .IN
        print("Direction = \(gp.direction)")
        // gp.onFalling { gpio in
        //     print("Falling, current value:" + String(gpio.value))
        // }
        gp.onChange{ gpio in
            // gpio.clearListeners()
            print("The value changed, current value:" + String(gpio.value))
        }  
        print("Montitoring Ending")
    }
    
    static func setGPIO(on: Bool) {
        let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi4)
        guard let gp = gpios[.P21] else {
            print("Could not read GPIO")
            return
        }

        gp.direction = .OUT
        gp.value = on ? 1 : 0
        print(gp.value)
    }
}
