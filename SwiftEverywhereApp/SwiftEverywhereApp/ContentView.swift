import SwiftUI

struct ContentView: View {
    @State var led: LEDResponse = LEDResponse(on: false)
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
                    if led.on {
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

    func loadLEDState() async throws {
        guard let url = URL(string: "\(serverURL)/led") else {
            print("Invalid URL")
            return
        }
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        let value = try JSONDecoder().decode(LEDResponse.self, from: data)
        self.led = value
    }

    @MainActor
    func toggleLEDState() async throws {
        guard let url = URL(string: "\(serverURL)/led") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let newState = LEDResponse(on: !led.on)
        let encodedData = try JSONEncoder().encode(newState)
        request.httpBody = encodedData

        let (data, _) = try await URLSession.shared.data(for: request)
        self.led = try JSONDecoder().decode(LEDResponse.self, from: data)
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

struct LEDResponse: Codable {
    let on: Bool
}
