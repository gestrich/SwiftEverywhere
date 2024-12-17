import SECommon
@preconcurrency import SwiftyGPIO
import Vapor

func routes(_ app: Application, mpc: PiController) throws {
    // Setup
    app.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(1), delay: .minutes(5)) { task in
        Task {
            let reading = try await mpc.getLightSensorReading()
            _ = try await piClient().updateLightSensorReading(reading)
            let analogReading = try await mpc.getAnalogReading(channel: 1)
            _ = try await piClient().updateAnalogReading(reading: analogReading)
        }
    }
    
    for path in PiClientAPIPaths.allCases {
        switch path {
        case .analogReading:
            app.get(PathComponent(stringLiteral: path.rawValue), ":channel") { request in
                guard let channel = request.parameters.get("channel", as: Int.self) else {
                    throw RoutesError.missingChannel
                }
                return try await mpc.getAnalogReading(channel: channel)
            }
        case .analogReadings:
            app.post(path.rawValue.pathComponents) { request in
                guard let channel = request.parameters.get("channel", as: Int.self) else {
                    throw RoutesError.missingChannel
                }
                guard let data = request.body.data else {
                    throw RoutesError.unexpectedBody
                }
                let request = try jsonDecoder().decode(DateRangeRequest.self, from: data)
                return try await piClient().getAnalogReadings(channel: channel, range: request)
            }
        case .host:
            app.post(path.rawValue.pathComponents) { request in
                guard let data = request.body.data else {
                    throw RoutesError.unexpectedBody
                }
                let host = try jsonDecoder().decode(Host.self, from: data)
                return try await piClient().postHost(host)
            }
        case .led:
            app.get(path.rawValue.pathComponents) { req in
                return try await mpc.getLEDState()
            }
            app.post(path.rawValue.pathComponents) { request in
                guard let data = request.body.data else {
                    throw RoutesError.unexpectedBody
                }
                let state = try jsonDecoder().decode(LEDState.self, from: data)
                return try await mpc.updateLEDState(state)
            }
        case .lightSensorReading:
            app.get(path.rawValue.pathComponents) { request in
                return try await mpc.getLightSensorReading()
            }
            app.post(path.rawValue.pathComponents) { request in
                let reading = try await mpc.getLightSensorReading()
                return try await piClient().updateLightSensorReading(reading)
            }
        case .lightSensorReadings:
            // This is not supported on Pi but isn't this a post?
            app.get(path.rawValue.pathComponents) { request in
                guard let data = request.body.data else {
                    throw RoutesError.unexpectedBody
                }
                let request = try jsonDecoder().decode(DateRangeRequest.self, from: data)
                return try await piClient().getLightSensorReadings(range: request)
            }
        }
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
    
    @Sendable
    func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    enum RoutesError: LocalizedError {
        case unexpectedBody
        case missingAPIGatewayURL
        case missingChannel
    }
}

extension AnalogReading: Content {
        
}
    
extension SECommon.Host: Content {
    
}

extension LEDState: Content {
    
}

extension LightSensorReading: Content {
    
}
