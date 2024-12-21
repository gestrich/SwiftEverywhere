import SECommon
@preconcurrency import SwiftyGPIO
import Vapor

func routes(_ app: Application, mpc: PiController) throws {
    // Setup
    let configuration = PiHardwareConfiguration()
    app.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(1), delay: .minutes(5)) { task in
        Task {
            for configuration in configuration.analogInputs {
                let reading = try await mpc.getAnalogReading(channel: configuration.channel)
                _ = try await piClient().updateAnalogReading(reading: reading)
            }
        }
    }
    
    Task {
        for digitalOutput in configuration.digitalOutputs {
            try await mpc.setupDigitalOutput(digitalOutput)
        }
    }
    
    for path in PiClientAPIPaths.allCases {
        switch path {
        case .analogReadings:
            app.get(PathComponent(stringLiteral: path.rawValue), ":channel") { request in
                guard let channel = request.parameters.get("channel", as: Int.self) else {
                    throw RoutesError.missingChannel
                }
                return try await mpc.getAnalogReading(channel: channel)
            }
            app.get(PathComponent(stringLiteral: path.rawValue)) { request in
                guard let channelString: String = request.query["channel"], let channel = Int(channelString) else {
                    throw RoutesError.missingChannel
                }
                
                guard let startDateQuery: String = request.query["startDate"] else {
                    throw RoutesError.missingRangeDate
                }
                guard let endDateQuery: String = request.query["endDate"] else {
                    throw RoutesError.missingRangeDate
                }
                let formatter = ISO8601DateFormatter()
                guard let startDate = formatter.date(from: startDateQuery) else {
                    throw RoutesError.missingRangeDate
                }
                guard let endDate = formatter.date(from: endDateQuery) else {
                    throw RoutesError.missingRangeDate
                }
                return try await mpc.getAnalogReadings(channel: channel, range: DateRangeRequest(startDate: startDate, endDate: endDate))
            }
        case .host:
            app.post(path.rawValue.pathComponents) { request in
                guard let data = request.body.data else {
                    throw RoutesError.unexpectedBody
                }
                let host = try jsonDecoder().decode(Host.self, from: data)
                return try await piClient().postHost(host)
            }
        case .digitalValues:
            app.get(PathComponent(stringLiteral: path.rawValue), ":channel") { request in
                guard let channel = request.parameters.get("channel", as: Int.self) else {
                    throw RoutesError.missingChannel
                }
                return try await mpc.getDigitalOutput(channel: channel)
            }
            app.post(path.rawValue.pathComponents) { request in
                guard let data = request.body.data else {
                    throw RoutesError.unexpectedBody
                }
                let state = try jsonDecoder().decode(DigitalValue.self, from: data)
                return try await mpc.updateDigitalReading(state)
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
        case missingAPIGatewayURL
        case missingChannel
        case missingRangeDate
        case unexpectedBody
    }
}

extension AnalogValue: Content {
        
}
    
extension SECommon.Host: Content {
    
}

extension DigitalValue: Content {
    
}
