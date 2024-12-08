import SECommon
import SwiftUI

struct ContentView: View {
    @State var ledState: LEDState = LEDState(on: false)
    @State private var showSettings = false
    @AppStorage("serverURL") private var serverURL: String = ""
    @State var viewLoaded = false

    var body: some View {
        VStack {
            Button {
                Task {
                    do {
                        try await toggleLEDState()
                        try await loadLEDState()
                    } catch {
                        print("Error: \(error)")
                    }
                }
            } label: {
                Group {
                    if ledState.on {
                        Image(systemName: "lightbulb.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.yellow)
                    } else {
                        Image(systemName: "lightbulb.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }.frame(width: 25)
            }.opacity(viewLoaded  ? 1.0 : 0.0)

            Button("Settings") {
                showSettings = true
            }
            .padding()
        }
        .padding()
        .task {
            do {
                try await loadLEDState()
                viewLoaded = true
            } catch {
                print("Error: \(error)")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(serverURL: $serverURL)
        }
    }

    @MainActor
    func loadLEDState() async throws {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        self.ledState = try await apiClient.getLEDState()
    }

    @MainActor
    func toggleLEDState() async throws {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        ledState = try await apiClient.updateLEDState(on: !ledState.on)
    }
    
    var apiClient: PiClientAPIImplementation? {
        guard let url = URL(string: "\(serverURL)") else {
            return nil
        }
        
        return PiClientAPIImplementation(baseURL: url)
    }
    
    enum ContentViewError: Error {
        case missingBaseURL
    }
}

struct SettingsView: View {
    @Binding var serverURL: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Configuration")) {
                    TextField("Server URL", text: $serverURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
