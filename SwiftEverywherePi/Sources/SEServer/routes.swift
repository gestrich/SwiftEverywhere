import SECommon
import SEGPIO
@preconcurrency import SwiftyGPIO
import Vapor

func routes(_ app: Application, mpc: MPCExample) throws {
    app.get { req async in
        "It works!"
    }

    app.get("led") { req in
        return try await mpc.getLEDState()
    }
    
    app.post("led") { request in
        guard let data = request.body.data else {
            throw RoutesError.unexpectedBody
        }
        let state = try JSONDecoder().decode(LEDState.self, from: data)
        return try await mpc.updateLEDState(on: state.on)
    }
}

extension LEDState: @retroactive Content {
    
}

enum RoutesError: LocalizedError {
    case unexpectedBody
}
