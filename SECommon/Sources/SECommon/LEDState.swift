
public struct LEDState: Codable, Sendable {
    public let on: Bool
    
    public init(on: Bool) {
        self.on = on
    }
}
