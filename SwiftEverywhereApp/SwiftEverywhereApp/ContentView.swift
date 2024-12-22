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
        NavigationStack {
            DeviceListView(viewModel: viewModel)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .none) {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel, urlStore: viewModel.urlStore)
            }
        }
    }
}
