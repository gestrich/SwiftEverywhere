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
        
        guard let apiGatewayEnvValue = Environment.get("API_GATEWAY_URL") else {
            throw RoutesError.missingAPIGatewayURL
        }
        
        guard let apiGatewayURL = URL(string: apiGatewayEnvValue) else {
            throw RoutesError.missingAPIGatewayURL
        }
        
        let host = try JSONDecoder().decode(Host.self, from: data)
        let client = PiClientAPIImplementation(baseURL: apiGatewayURL)
        return try await client.updateHost(ipAddress: host.ipAddress, port: host.port)
    }
}

extension SECommon.Host: Content {
    
}

extension LEDState: Content {
    
}

enum RoutesError: LocalizedError {
    case unexpectedBody
    case missingAPIGatewayURL
}
