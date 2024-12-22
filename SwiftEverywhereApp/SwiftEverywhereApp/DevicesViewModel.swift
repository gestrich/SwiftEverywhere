//
//  DevicesViewModel.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/21/24.
//

import Foundation
import SECommon
import SwiftUI

@Observable
class DevicesViewModel {
    let hardwareConfiguration = PiHardwareConfiguration()
    var urlStore: URLStore
    var analogStates: [AnalogInputState] = []
    var digitalOutputStates: [DigitalOutputState] = []
    
    init() {
        self.analogStates = []
        self.digitalOutputStates = []
        self.urlStore = URLStore()
        
        self.urlStore.urlStoreUpdated = { [weak self] in
            guard let self else { return }
            Task {
                try await self.loadStates()
            }
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("PUSH_NOTIFICATION_REGISTERED"), object: nil, queue: .main) { notification in
            Task {
                guard let dict = notification.userInfo as? [String: String], let token = dict["deviceToken"] else {
                    return
                }
                do {
                    try await self.apiClient?.updateDeviceToken(DeviceToken(token: token, deviceName: UIDevice.current.name))
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func loadStates() async throws {
        try await loadAnalogStates()
        try await loadDigitalOutputStates()
    }
    
    @MainActor
    func loadAnalogStates() async throws {
        var result = [AnalogInputState]()
        for configuration in hardwareConfiguration.analogInputs {
            let state = try await fetchAnalogState(configuration: configuration)
            result.append(state)
        }
        
        self.analogStates = result
    }
    
    func fetchAnalogState(configuration: AnalogInput) async throws -> AnalogInputState {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        let dateRange = DateRangeRequest(startDate: Date().addingTimeInterval(-60 * 60 * 24), endDate: Date())
        var readings = try await apiClient.getAnalogReadings(channel: configuration.channel, range: dateRange)
        let latestReading = try await apiClient.getAnalogReading(channel: configuration.channel)
        readings.append(latestReading)
        return AnalogInputState(configuration: configuration, readings: readings)
    }
    
    @MainActor
    func loadDigitalOutputStates() async throws {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        var result = [DigitalOutputState]()
        for configuration in hardwareConfiguration.digitalOutputs {
            let digitalValue = try await apiClient.getDigitalOutput(channel: configuration.channel)
            let digitalOutputState = DigitalOutputState(configuration: configuration, outputValues: [digitalValue])
            result.append(digitalOutputState)
        }
        
        self.digitalOutputStates = result
    }
    
    @MainActor
    func toggleDigitalOutputState(_ digitalOutputState: DigitalOutputState) async throws {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        let newState = DigitalValue(on: !digitalOutputState.latestValue.on, channel: digitalOutputState.configuration.channel)
        _ = try await apiClient.updateDigitalOutput(newState)
        try await loadDigitalOutputStates()
    }
    
    var selectedAPIURL: URL? {
        guard urlStore.serverURLs.indices.contains(urlStore.selectedServerIndex),
              let url = URL(string: urlStore.serverURLs[urlStore.selectedServerIndex]) else {
            return nil
        }
        return url
    }
    
    var apiClient: PiClientAPIImplementation? {
        guard let selectedAPIURL else {
            return nil
        }
        
        return PiClientAPIImplementation(baseURL: selectedAPIURL)
    }
    
    private enum ContentViewError: Error {
        case missingBaseURL
    }
}

struct AnalogInputState: Sendable, Identifiable, Hashable {
    let configuration: AnalogInput
    let readings: [AnalogValue]
    
    var latestReading: AnalogValue {
        return readings.last ?? AnalogValue(channel: configuration.channel, uploadDate: Date(), value: 0.0)
    }

    var id: String {
        return configuration.name + latestReading.uploadDate.description
    }
    
    func chartYRange() -> ClosedRange<Double> {
        let values = readings.map{$0.value}.map({configuration.displayableValue(reading: $0)})
        let lowerBound: Double
        
        if let minValue = values.min() {
            lowerBound = min(minValue, configuration.typicalRange.lowerBound)
        } else {
            lowerBound = configuration.typicalRange.lowerBound
        }
        let upperBound: Double
        if let maxValue = values.max() {
            upperBound = max(maxValue, configuration.typicalRange.upperBound)
        } else {
            upperBound = configuration.typicalRange.upperBound
        }
        return lowerBound...upperBound
    }
    
    static func == (lhs: AnalogInputState, rhs: AnalogInputState) -> Bool {
        lhs.id == rhs.id && lhs.readings == rhs.readings
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(readings)
    }
}

struct DigitalOutputState: Sendable, Identifiable {
    let configuration: DigitalOutput
    var latestValue: DigitalValue {
        return outputValues.last ?? DigitalValue(on: false, channel: configuration.channel)
    }
    let outputValues: [DigitalValue]
    
    var id: String {
        return configuration.name + "\(latestValue)"
    }
}
