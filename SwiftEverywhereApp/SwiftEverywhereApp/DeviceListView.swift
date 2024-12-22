//
//  DeviceListView.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/21/24.
//

import SECommon
import SwiftUI

struct DeviceListView: View {
    let viewModel: DevicesViewModel
    
    @State var viewLoaded = false
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        List {
            Section() {
                ForEach (viewModel.digitalOutputStates) { digitalOutputState in
                    LabeledContent(digitalOutputState.configuration.name) {
                        Button {
                            Task {
                                do {
                                    try await viewModel.toggleDigitalOutputState(digitalOutputState)
                                } catch {
                                    print("Error: \(error)")
                                }
                            }
                        } label: {
                            Image(systemName: "lightbulb.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(digitalOutputState.latestValue.on ? Color.yellow : Color.gray )
                                .frame(maxWidth: 22)
                                .padding()
                        }
                    }
                    
                }
            }
            ForEach (viewModel.analogStates) { analogState in
                Section {
                    VStack {
                        NavigationLink(value: analogState) {
                            HStack {
                                LabeledContent(analogState.configuration.name, value: analogState.configuration.displayableLabel(reading: analogState.latestReading.value))
                            }
                        }
                        AnalogReadingsChart(analogState: analogState)
                    }
                    
                }
            }
            Section {
                if let url = viewModel.selectedAPIURL {
                    Text("Connected to: \(url)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
        }
        .refreshable {
            Task {
                try await viewModel.loadStates()
            }
        }
        .opacity(viewLoaded ? 1.0 : 0.0)
        .navigationTitle("Swift Everywhere")
        .task {
            do {
                try await viewModel.loadStates()
            } catch {
                print("Error: \(error)")
            }
            viewLoaded = true
        }
        .onChange(of: scenePhase) { (oldPhase, newPhase) in
            if newPhase == .active {
                Task {
                    try await viewModel.loadStates()
                }
            }
        }
        .onReceive(timer, perform: { _ in
            Task {
                try await viewModel.loadStates()
            }
        })
        .navigationDestination(for: AnalogInputState.self) { state in
            // The values in navigationDestination are not Bindable so we need enough
            // info for the child view to query it for changes for real-time updates.
            DeviceDetailView(analogInputName: state.configuration.name, viewModel: viewModel)
        }
    }
    
    private enum ContentViewError: Error {
        case missingBaseURL
    }
}

extension AnalogValue: @retroactive Identifiable {
    public var id: Date {
        return uploadDate
    }
}
