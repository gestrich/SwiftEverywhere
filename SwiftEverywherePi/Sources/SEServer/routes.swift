import SEGPIO
@preconcurrency import SwiftyGPIO
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("led") { req async -> Bool in
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        guard let ledGPIO = gpios[.P21] else {
            print("Could not read GPIO")
            return false
        }
        ledGPIO.direction = .OUT
        return ledGPIO.value == 1 ? true : false
    }
}
