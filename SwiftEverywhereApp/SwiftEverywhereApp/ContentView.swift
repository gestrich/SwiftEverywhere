//
//  ContentView.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/7/24.
//

import SECommon
import SwiftUI

struct ContentView: View {
    @StateObject var urlStore = URLStore()
    let hardwareConfiguration = PiHardwareConfiguration()
    @State var analogStates: [AnalogInputState] = []
    @State var digitalOutputStates: [DigitalOutputState] = []
    @State private var showSettings = false
    @State var viewLoaded = false
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                ForEach (digitalOutputStates) { digitalOutputState in
                    Section(digitalOutputState.configuration.name) {
                        Button {
                            Task {
                                do {
                                    try await toggleDigitalOutputState(digitalOutputState)
                                } catch {
                                    print("Error: \(error)")
                                }
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "lightbulb.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundStyle(digitalOutputState.latestValue.on ? Color.yellow : Color.gray )
                                    .frame(width: 25)
                            }
                        }
                    }
                }
                ForEach (analogStates) { analogState in
                    Section(analogState.configuration.name) {
                        AnalogReadingsChart(analogState: analogState)
                    }
                }

                Section {
                    if urlStore.serverURLs.indices.contains(urlStore.selectedServerIndex) {
                        Text("Connected to: \(urlStore.serverURLs[urlStore.selectedServerIndex])")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
            }.opacity(viewLoaded ? 1.0 : 0.0)
            .navigationTitle("Swift Everywhere")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Settings") {
                        showSettings = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            try await loadStates()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(urlStore: urlStore)
        }
        .task {
            do {
                try await loadStates()
            } catch {
                print("Error: \(error)")
            }
            viewLoaded = true
        }
        .onChange(of: scenePhase) { (oldPhase, newPhase) in
            if newPhase == .active {
                Task {
                    try await loadStates()
                }
            }
        }
        .onReceive(timer, perform: { _ in
            Task {
                try await loadStates()
            }
        })
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
        _ = try await apiClient.updateDigitalReading(newState)
        try await loadDigitalOutputStates()
    }
    
    var apiClient: PiClientAPIImplementation? {
        guard urlStore.serverURLs.indices.contains(urlStore.selectedServerIndex),
              let url = URL(string: urlStore.serverURLs[urlStore.selectedServerIndex]) else {
            return nil
        }
        
        return PiClientAPIImplementation(baseURL: url)
    }
    
    enum ContentViewError: Error {
        case missingBaseURL
    }
}

extension AnalogValue: @retroactive Identifiable {
    public var id: Date {
        return uploadDate
    }
}

struct AnalogInputState: Sendable, Identifiable {
    let configuration: AnalogInput
    var latestReading: AnalogValue {
        return readings.last ?? AnalogValue(channel: configuration.channel, uploadDate: Date(), value: 0.0)
    }
    let readings: [AnalogValue]
    
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
