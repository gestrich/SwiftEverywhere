//
//  ContentView.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/7/24.
//

import SECommon
import SwiftUI

struct ContentView: View {
    @State private var showSettings = false
    var viewModel = DevicesViewModel()
    var body: some View {
        NavigationView {
            DeviceListView(viewModel: viewModel)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Settings") {
                        showSettings = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            try await viewModel.loadStates()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(urlStore: viewModel.urlStore)
            }
        }
    }
}
