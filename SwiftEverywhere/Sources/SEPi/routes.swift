import SECommon
@preconcurrency import SwiftyGPIO
import Vapor

func routes(_ app: Application, mpc: PiController) throws {
    // Setup
    app.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(1), delay: .minutes(5)) { task in
        Task {
            let reading = try await mpc.getLightSensorReading()
            _ = try await piClient().updateLightSensorReading(value: reading.value)
        }
    }
    
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
    
    app.post("lightSensorValue") { request in
        return try await mpc.getLightSensorReading()
    }
    
    app.post("updateHost") { request in
        guard let data = request.body.data else {
            throw RoutesError.unexpectedBody
        }
        let host = try JSONDecoder().decode(Host.self, from: data)
        return try await piClient().updateHost(ipAddress: host.ipAddress, port: host.port)
    }
    
    @Sendable
    func piClient() async throws -> PiClientAPIImplementation {
        guard let apiGatewayEnvValue = Environment.get("API_GATEWAY_URL") else {
            throw RoutesError.missingAPIGatewayURL
        }
        
        guard let apiGatewayURL = URL(string: apiGatewayEnvValue) else {
            throw RoutesError.missingAPIGatewayURL
        }
        
        return PiClientAPIImplementation(baseURL: apiGatewayURL)
    }
}

extension SECommon.Host: Content {
    
}

extension LEDState: Content {
    
}

extension LightSensorReading: Content {
    
}

private enum RoutesError: LocalizedError {
    case unexpectedBody
    case missingAPIGatewayURL
}
