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
    
    app.post("updateHost") { request in
        guard let data = request.body.data else {
            throw RoutesError.unexpectedBody
        }
        let hostUpdate = try JSONDecoder().decode(HostUpdate.self, from: data)
        let client = PiClientAPIImplementation(baseURL: URL(string: hostUpdate.updateURL)!)
        // TODO: Why is it saying `Host` is not able to be returned?
        return try await client.updateHost(ipAddress: hostUpdate.host.ipAddress)
    }
}

struct HostUpdate: Codable {
    let updateURL: String
    let host: SECommon.Host
}

extension SECommon.Host: Content {
    
}

extension LEDState: Content {
    
}

enum RoutesError: LocalizedError {
    case unexpectedBody
}
