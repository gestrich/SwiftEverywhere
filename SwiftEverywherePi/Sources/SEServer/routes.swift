import SEGPIO
@preconcurrency import SwiftyGPIO
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("led") { req in
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        guard let ledGPIO = gpios[.P21] else {
            print("Could not read GPIO")
            throw RoutesError.gpioError
        }
        ledGPIO.direction = .OUT
        return LEDState(on: ledGPIO.value == 1 ? true : false)
    }
    
    app.post("led") { request in
        guard let data = request.body.data else {
            throw RoutesError.unexpectedBody
        }
        let state = try JSONDecoder().decode(LEDState.self, from: data)
        let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
        guard let ledGPIO = gpios[.P21] else {
            print("Could not read GPIO")
            throw RoutesError.gpioError
        }
        ledGPIO.direction = .OUT
        ledGPIO.value = state.on ? 1 : 0
        return state
    }
}

struct LEDState: Content {
    let on: Bool
}

enum RoutesError: LocalizedError {
    case unexpectedBody
    case gpioError
}
