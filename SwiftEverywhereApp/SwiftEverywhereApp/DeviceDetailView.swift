//
//  DeviceDetailView.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/21/24.
//

import SwiftUI

struct DeviceDetailView: View {
    let analogInputName: String
    let viewModel: DevicesViewModel
    init(analogInputName: String, viewModel: DevicesViewModel) {
        self.analogInputName = analogInputName
        self.viewModel = viewModel
    }
    
    var analogInputState: AnalogInputState? {
        return viewModel.analogStates.first(where: {$0.configuration.name == analogInputName})
    }
    
    var body: some View {
        Group {
            if let analogInputState {
                List {
                    Section {
                        LabeledContent("Name", value: analogInputState.configuration.name)
                        LabeledContent("Pin", value: String(analogInputState.configuration.channel))
                        LabeledContent("Value", value: analogInputState.configuration.displayableLabel(reading: analogInputState.latestReading.value))
                        LabeledContent("Input", value: "\(analogInputState.configuration.voltage.rawValue)V")
                        LabeledContent("Output", value: "\(format(analogInputState.latestReading.value, decimalCount: 1))V")
                    }
                    Section {
                        AnalogReadingsChart(analogState: analogInputState)
                    }
                }.refreshable {
                    Task {
                        try await viewModel.loadStates()
                    }
                }
            } else {
                Text("\(analogInputName) not found")
            }
        }
    }
    
    func format(_ number: Double, decimalCount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalCount
        formatter.maximumFractionDigits = decimalCount

        return formatter.string(for: number) ?? "N/A"
    }
}
