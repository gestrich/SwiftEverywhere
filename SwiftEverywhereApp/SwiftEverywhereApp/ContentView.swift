import Combine
import Foundation
import SECommon
import SwiftUI

struct ContentView: View {
    @StateObject var urlStore = URLStore()
    @State var ledState: LEDState = LEDState(on: false)
    @State private var showSettings = false
    @State var viewLoaded = false

    var body: some View {
        NavigationView {
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
                }.opacity(viewLoaded ? 1.0 : 0.0)
                .padding()

                if urlStore.serverURLs.indices.contains(urlStore.selectedServerIndex) {
                    Text("Connected to: \(urlStore.serverURLs[urlStore.selectedServerIndex])")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top)
                }
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
            .navigationTitle("LED Controller")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Settings") {
                        showSettings = true
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(urlStore: urlStore)
            }
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

struct SettingsView: View {
    @ObservedObject var urlStore: URLStore
    @Environment(\.dismiss) private var dismiss
    @State private var newURL: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server URLs")) {
                    List {
                        ForEach(urlStore.serverURLs.indices, id: \.self) { index in
                            HStack {
                                Text(urlStore.serverURLs[index])
                                Spacer()
                                if urlStore.selectedServerIndex == index {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .onTapGesture {
                                urlStore.selectedServerIndex = index
                                dismiss()
                            }
                        }
                        .onDelete { offsets in
                            urlStore.serverURLs.remove(atOffsets: offsets)
                            if urlStore.selectedServerIndex >= urlStore.serverURLs.count {
                                urlStore.selectedServerIndex = max(0, urlStore.serverURLs.count - 1)
                            }
                        }
                    }
                }
                
                Section(header: Text("Add New Server")) {
                    TextField("New Server URL", text: $newURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    Button("Add") {
                        guard !newURL.isEmpty else { return }
                        urlStore.serverURLs.append(newURL)
                        newURL = ""
                    }
                    .disabled(newURL.isEmpty)
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

class URLStore: ObservableObject {
    @Published var serverURLs: [String]
    @Published var selectedServerIndex: Int

    private let urlsKey = "serverURLs"
    private let selectedIndexKey = "selectedServerIndex"
    private var cancellables: Set<AnyCancellable> = []

    init() {
        // Load stored data or provide defaults
        if let data = UserDefaults.standard.data(forKey: urlsKey),
           let urls = try? JSONDecoder().decode([String].self, from: data) {
            self.serverURLs = urls
        } else {
            self.serverURLs = []
        }

        self.selectedServerIndex = UserDefaults.standard.integer(forKey: selectedIndexKey)

        // Save changes automatically when values change
        $serverURLs
            .sink { [weak self] urls in
                guard let self else { return }
                if let data = try? JSONEncoder().encode(urls) {
                    UserDefaults.standard.set(data, forKey: self.urlsKey)
                }
            }
            .store(in: &cancellables)

        $selectedServerIndex
            .sink { [weak self] index in
                guard let self else { return }
                UserDefaults.standard.set(index, forKey: self.selectedIndexKey)
            }
            .store(in: &cancellables)
    }
}
