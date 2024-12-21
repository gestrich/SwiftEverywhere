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
        
        Form {
            ForEach (viewModel.digitalOutputStates) { digitalOutputState in
                Section(digitalOutputState.configuration.name) {
                    Button {
                        Task {
                            do {
                                try await viewModel.toggleDigitalOutputState(digitalOutputState)
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
            ForEach (viewModel.analogStates) { analogState in
                Section(analogState.configuration.name) {
                    AnalogReadingsChart(analogState: analogState)
                }
            }
            
            Section {
                if let url = viewModel.selectedAPIURL {
                    Text("Connected to: \(url)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
        }.opacity(viewLoaded ? 1.0 : 0.0)
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
