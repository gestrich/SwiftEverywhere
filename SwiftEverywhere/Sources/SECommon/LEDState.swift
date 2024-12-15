
public struct LEDState: Codable, Sendable, Equatable {
    public let on: Bool
    
    public init(on: Bool) {
        self.on = on
    }
}
